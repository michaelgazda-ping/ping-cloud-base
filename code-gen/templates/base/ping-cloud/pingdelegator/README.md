# Delegated Admin Notes

This document covers some important notes regarding how to deploy Delegated Admin in P1AS.

## Delegated Admin out-of-the-box configuration

In the out-of-the-box configuration, Delegated Admin rights are provided to the admin user `uid=admin,${USER_BASE_DN}`. 
Delegated Admin rights may only be granted to a single LDAP user or to a single LDAP group but not both. So an LDAP 
group is required to grant Delegated Admin rights to more than one user. Even for a single admin user, the recommended 
approach is to create an LDAP group, add the admin user to that group and grant Delegated Admin rights to the group 
as a whole. The out-of-the-box configuration is set up with a user only for convenience so that it works with data 
loaded using the example MakeLDIF templates. 

## How to create an LDAP group and add users to the group

An LDAP group may be created using the following LDIF:

```shell
dn: cn=administrators,${GROUP_BASE_DN}
objectClass: groupOfUniqueNames
cn: administrators
uniquemember: uid=admin,${GROUP_BASE_DN}
```

where `GROUP_BASE_DN` is the base DN of the LDAP group under `USER_BASE_DN` for the customer environment. It could 
simply be the same as `USER_BASE_DN` in test environments.

## How to grant delegated admin rights to the group

After creating the LDAP group, grant the group Delegated Admin rights by adding the following `dsconfig` command to 
the bottom of `profiles/pingdirectory/pd.profile/misc-files/delegated-admin/01-add-delegated-admin.dsconfig.subst` in 
the cluster-state repo. Note that this will be effected only on the next rollout of the PingDirectory servers.

```shell
dsconfig set-delegated-admin-rights-prop \
    --rights-name administrator-user-${DA_IMPLICIT_GRANT_TYPE_CLIENT_ID} \
    --remove admin-user-dn:uid=admin,${USER_BASE_DN} \
    --set admin-group-dn:cn=administrators,${USER_BASE_DN}
```

## Changing the USER_BASE_DN

Changing the `USER_BASE_DN` requires completely rolling out every PingDirectory server in the replication topology, 
followed by rolling out all PingFederate servers (admin and engines). Use the `LAST_UPDATE_REASON` environment 
variable to roll out PingDirectory and PingFederate servers sequentially.

## Fixing Delegated Admin warnings on PingDirectory

### Determining if there are problems with the Delegated Admin configuration or data 

- In the server's status output (run the `status` tool from the CLI), alerts and alarms will be displayed when there are
  problems with Delegated Admin configuration or data.
- On the Delegated Admin UI, the user will be presented with a yellow banner with the following warning message:
`Please contact your administrator. The current Delegated Admin configuration is invalid.`

### Fixing Delegated Admin configuration warnings

The Delegated Admin configuration is set up after the server has started through a post-start hook script. If the 
configuration contains references to LDAP data that does not yet exist (e.g. references to the 
`uid=admin,${USER_BASE_DN}` LDAP user or the `cn=administrators,${GROUP_BASE_DN}` LDAP group), then the Delegated Admin 
configuration will be considered invalid, but it is just a warning, not an error. 

To fix the issue, the PD servers must be re-rolled after creating the missing LDAP data references. Run the `status` 
tool to confirm that all invalid configuration is fixed. You may need more than one restart to get it right for the 
customer's user data.

### Fixing Delegated Admin data warnings

This is *only* a problem for existing customers. The `USER_BASE_DN` entry contains an ACI that's too permissive. Run 
the `ldapmodify` command and type in the following LDIF interactively to fix it:

```shell
dn: ${USER_BASE_DN}
changetype: modify
delete: aci
aci: (targetattr!="userPassword")(version 3.0; acl "Allow anonymous read access for anyone"; allow (read,search,compare) userdn="ldap:///anyone";)
-
add: aci
aci: (targetattr!="userPassword")(version 3.0; acl "Allow read access for all"; allow (read,search,compare) userdn="ldap:///all";)

<Hit enter key twice to apply the modifications>
```

Replace `USER_BASE_DN` above with the `USER_BASE_DN` for the customer environment.

## Integrating existing customers with Delegated Admin

- Add the `dsconfig` command mentioned earlier into the PingDirectory profile in the correct location. Note that since 
  Delegated Admin configuration is set up post server startup, it is not located in the normal `dsconfig` directory 
  that `manage-profile` uses. Also, the file has a `.subst` extension so variable substitutions work as expected.
- Apply the ACI change from the above section to the base user entry to prevent warnings about invalid configuration in 
  the Delegated Admin application.
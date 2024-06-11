# PAAS LDAP openldap server initialization script
# initializes a blank openldap server using root external bind
# requires user input for base dn, admin user, and admin user password
# requires slapd ldap-util

export BASE_DN=''
export ADMIN_ID=''
export ADMIN_EMAIL=''
export ADMIN_CN=''
export ADMIN_SN=''
export ADMIN_PASSWD=''
export CA_FILE=''
export CERT_FILE=''
export KEY_FILE=''
DO_AUTH=1
DO_INIT=1
DO_TLS=1

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-auth)
        DO_AUTH=0
        shift # past argument
        ;;
        --skip-init)
        DO_INIT=0
        shift # past pargument
        ;;
        --skip-tls)
        DO_TLS=0
        shift # past argument
        ;;
        -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
        *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "Operations:"
echo "DO FIRST TIME = ${DO_INIT}"
echo "DO AUTH       = ${DO_AUTH}"
echo "DO TLS        = ${DO_TLS}"
echo "+===============+"

read -p "Base DN: " BASE_DN

if [ "$DO_INIT" = 1 ]; then
    read -p "Admin User ID: " ADMIN_ID
    read -p "Admin User Email: " ADMIN_EMAIL
    read -p "Admin User CN: " ADMIN_CN
    read -p "Admin User SN: " ADMIN_SN
    while 
        read -s -p "Admin Password: " ADMIN_PASSWD
        echo ""
        read -s -p "Confirm Password: " CONFIRM_PASSWD
        echo ""
        ! [ "$ADMIN_PASSWD" = "$CONFIRM_PASSWD" ]
    do echo "Passwords must match" ; done
fi

if [ "$DO_TLS" = 1 ]; then
    read -p "CA Cert File Path: " CA_FILE
    read -p "Server Cert File Path: " CERT_FILE
    read -p "Server Key File Path: " KEY_FILE
fi

if [ "$DO_AUTH" = 1 ]; then
    envsubst '$BASE_DN' < auth.template.ldif > auth.ldif
    sudo ldapmodify -H ldapi:/// -Y EXTERNAL -f auth.ldif
    rm auth.ldif
fi

if [ "$DO_INIT" = 1 ]; then
    envsubst '$BASE_DN' < pass.template.ldif > pass.ldif
    envsubst '$BASE_DN:$ADMIN_ID:$ADMIN_EMAIL:$ADMIN_CN:$ADMIN_SN:$ADMIN_PASSWD' < init.template.ldif > init.ldif
    sudo ldapmodify -H ldapi:/// -Y EXTERNAL -f pass.ldif
    sudo ldapadd -H ldapi:/// -Y EXTERNAL -c -f init.ldif
    rm pass.ldif init.ldif
fi

if [ "$DO_TLS" = 1 ]; then
    envsubst '$CA_FILE:$CERT_FILE:$KEY_FILE' < tls.template.ldif > tls.ldif
    sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f tls.ldif
    rm tls.ldif
fi

unset BASE_DN
unset ADMIN_ID
unset ADMIN_CN
unset ADMIN_SN
unset ADMIN_PASSWD
unset CA_FILE
unset CERT_FILE
unset KEY_FILE
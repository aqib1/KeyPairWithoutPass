set -eux

function validateParams () {
    if [ "$#" -ne 1 ]; then
        echo "Illegal numbers of parameters"
        echo "Environment name is not defined in parameters"
        echo "kylin_create_keystore.sh [ENV]"
        exit 1
    fi
}


function create_keystore() {
    validateParams $*
    site_name=Temp-$1.example.com
    password="TEST1234"
    pass_phrase="TEST1234TEST"
    ou="TEMP"
    country="HU"
    state="Budapest"
    matchForRSAPrivateKeyHeader="BEGIN RSA PRIVATE KEY"
    matchForRSAPrivateKeyFooter="END RSA PRIVATE KEY"
    matchForPublicKeyHeader="BEGIN PUBLIC KEY"
    matchForPublicKeyFooter="END PUBLIC KEY"
    echo "Kylin endpoint received ["${site_name}+"]"
    keytool -genkeypair -dname "cn=${site_name}, ou=${ou}, o=${ou}, c=${country} st=${state}" -alias server -keyalg RSA -keysize 2048 -keystore ${site_name}.jks --storepass ${password}
    keytool -importkeystore -srckeystore ${site_name}.jks --srcstorepass ${password} -destkeystore ${site_name}.p12 -srcstoretype jks -deststoretype pkcs12 --storepass ${password}
    openssl pkcs12 -in ${site_name}.p12 -out ${site_name}.pem -passin pass:${password} -passout pass:${pass_phrase}
    openssl rsa -in ${site_name}.pem -out ${site_name}.private.key -passin pass:${pass_phrase}
    openssl rsa -in ${site_name}.pem -pubout > ${site_name}.public.key -passin pass:${pass_phrase}
    openssl req -new -key ${site_name}.private.key -out ${site_name}.csr -subj "/CN=${site_name}/OU=${ou}/O=${ou}/C=${country}/ST=${state}"
    private_key=$(sed -n "/${matchForRSAPrivateKeyHeader}/,/${matchForRSAPrivateKeyFooter}/{//!p;}" ${site_name}.private.key);
    public_key=$(sed -n "/${matchForPublicKeyHeader}/,/${matchForPublicKeyFooter}/{//!p;}" ${site_name}.public.key);
    keypair_json=$(jq -n \
                    --arg pk "${private_key}" \
                    --arg pub "${public_key}" \
                    '{private_key: $pk, public_key: $pub}'
    );
    echo "keypair json created " ${keypair_json} 
}

create_keystore $*


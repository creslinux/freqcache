str="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
here=${str%/*}
cd ${here}

docker build -t freqcache_ft_ca .
docker run -d --name ft_ca freqcache_ft_ca

docker exec -it ft_ca /usr/share/easy-rsa/easyrsa init-pki
docker exec -it ft_ca /usr/share/easy-rsa/easyrsa build-ca nopass
docker exec -it ft_ca /usr/share/easy-rsa/easyrsa  gen-dh

for x in `cat api-list `  
do 
   docker exec -it ft_ca /usr/share/easy-rsa/easyrsa build-server-full ${x} nopass
done

docker cp ft_ca:/easyrsa ca

mkdir ca/pki/pem
for x in `cat api-list `
do 
  grep -A 1000 BEGIN ca/pki/issued/${x}.crt > c
  grep -A 1000 BEGIN  ca/pki/private/${x}.key > k
  cat c k > ${x}.pem
  mv ${x}.pem ca/pki/pem/${x}.pem
  echo "##################################################################"
  echo " Built Cert and Key for ${x} "
  echo "##################################################################"
  cat  ca/pki/pem/${x}.pem
  rm c
  rm k
done

cd ..

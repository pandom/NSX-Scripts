join management-plane 192.168.254.19 username admin thumbprint a7ba094dea71062f942f814ba750091e6347eeaf89538f92886cab06caa22b04 password


join management-plane 192.168.254.19 username admin thumbprint a7ba094dea71062f942f814ba750091e6347eeaf89538f92886cab06caa22b04 password VMware1!


26e68ad3ebfccc58505be6873c1090e6ce82bedc60f7d0402c4ab90df64588ee

[root@srv-030:~] openssl x509 -in /etc/vmware/ssl/rui.crt -fingerprint -sha1 -noout
SHA1 Fingerprint=13:65:EB:11:91:0B:97:B8:30:62:DB:35:28:D4:A7:92:3D:D2:A1:68

[root@srv-031:/var/log] openssl x509 -in /etc/vmware/ssl/rui.crt -fingerprint -sha1 -noout
SHA1 Fingerprint=3D4E8F3CA30A2FFC5600C670E00154FB9F1648A0

detach management-plane 192.168.254.19 username admin password VMware1! thumbprint a7ba094dea71062f942f814ba750091e6347eeaf89538f92886cab06caa22b04

vsipioctl clearallfilters
etc/init.d/netcpad stop
/etc/init.d/netcpad stop
/etc/init.d/nsx-exporter   stop  
/etc/init.d/nsx-nestdb  stop                
/etc/init.d/nsx-support-bundle-client stop
/etc/init.d/nsx-ctxteng   stop              
/etc/init.d/nsx-sfhc stop
/etc/init.d/nsx-da  stop                    
/etc/init.d/nsx-hyperbus   stop             
/etc/init.d/nsx-lldp  stop                  
/etc/init.d/nsx-platform-client stop
/etc/init.d/nsx-mpa   stop  
/etc/init.d/nsx-datapath   stop  
/etc/init.d/nsx-ctxteng   stop
/etc/init.d/nsx-hyperbus   stop 
/etc/init.d/nsx-metrics-libs  stop   
/etc/init.d/nsx-nestdb-libs  stop   
/etc/init.d/nsx-nestdb   stop 
/etc/init.d/nsx-platform-client  stop
/etc/init.d/nsx-rpc-libs stop
/etc/init.d/nsx-shared-libs stop 
/etc/init.d/nsx-common-libs stop

esxcli software vib remove -n nsx-aggservice -f 
esxcli software vib remove -n nsx-da -f 
esxcli software vib remove -n nsx-esx-datapath -f 
esxcli software vib remove -n nsx-exporter -f 
esxcli software vib remove -n nsx-host -f 
esxcli software vib remove -n nsx-lldp -f 
esxcli software vib remove -n nsx-netcpa -f 
esxcli software vib remove -n nsx-python-protobuf -f 
esxcli software vib remove -n nsx-sfhc -f 
esxcli software vib remove -n nsx-support-bundle-client -f 
esxcli software vib remove -n nsxa -f 
esxcli software vib remove -n nsxcli -f  
esxcli software vib remove -n nsx-mpa -f
esxcli software vib remove -n nsx-ctxteng   -f
esxcli software vib remove -n nsx-hyperbus   -f 
esxcli software vib remove -n nsx-metrics-libs  -f   
esxcli software vib remove -n nsx-nestdb-libs  -f   
esxcli software vib remove -n nsx-nestdb   -f 
esxcli software vib remove -n nsx-platform-client  -f
esxcli software vib remove -n nsx-rpc-libs -f
esxcli software vib remove -n nsx-shared-libs -f
esxcli software vib remove -n nsx-common-libs -f


##MANUAL INSTALL
esxcli software vib install -d /tmp/nsx-lcp-2.0.0.0.0.6080953-esx65.zip -f
##MANUAL BINDING
/opt/vmware/nsx-cli/bin/scripts/nsxcli
join management-plane 192.168.254.19 username admin thumbprint a7ba094dea71062f942f814ba750091e6347eeaf89538f92886cab06caa22b04 password VMware1!




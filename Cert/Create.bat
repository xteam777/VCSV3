makecert -r -pe -n "CN=Vircess.com" -ss CA -sr CurrentUser ^
	 -a sha256 -cy authority -sky signature -sv VircessCA.pvk VircessCA.cer
certutil -user -addstore Root VircessCA.cer
makecert -pe -n "CN=Vircess.com" -a sha256 -cy end ^
         -sky signature ^
         -ic VircessCA.cer -iv VircessCA.pvk ^
         -sv VircessSPC.pvk VircessSPC.cer
pvk2pfx -pvk VircessSPC.pvk -spc VircessSPC.cer -pfx VircessSPC.pfx
pause
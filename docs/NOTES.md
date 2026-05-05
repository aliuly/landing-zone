# TODO

* [x] Remove sensitive flags from regions calculated from otc credentials
  nonsensitive(variable)
* [x] nginx configuration to include internal host
* [x] add domain to resolve list
* [x] idp should request a TLS certificate for internal host
* [x] move idp data volumes to its own volume so we can re-build
  and keep data.
  - move IDP data
  - Keep TLS certs here
- [ ] configure logtank service

***

* External hosts are www-name, internal hosts just name.

# More work
- [ ] split-horizon DNS (internal vs. external zones)
- [ ] rdesktop => jumpserver
- [ ] Compliance as code hardening
- [ ] EVS encryption
- [ ] Split deployment description from AWS state

# Landing Zone concept

* Central Enterprise Router - Hub
	* Alternate: Use a Hub VPC
* Attachments:
	* VPC
	* VPN - Uses an  _Access_ VPC
	* Virtual Gateway (Direct Connect)
	* CFW - Cloudia says a VPC is required
		* **This needs to be created from Enterprise Router**
		* Firewall VPC with CFW in Enterprise Router mode
		* Alternate: Replace CFW with customer custom VM
* VPC with Jump server and IdP
* VPC with VPN
* VPC with

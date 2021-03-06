.PHONY: default help install uninstall pull update logo mrproper package

PROG 		= islet
VERSION		= 1.3.7
CONFIG_DIR 	= /etc/$(PROG)
INSTALL_DIR 	= /opt/$(PROG)
LIB_DIR		= $(INSTALL_DIR)/lib
CRON_DIR 	= $(INSTALL_DIR)/cron
BIN_DIR 	= $(INSTALL_DIR)/bin
PLUGIN_DIR 	= $(INSTALL_DIR)/plugins
MAN_DIR 	= /usr/share/man
CRON 		= /etc/cron.d
FUNCTIONS 	= ./functions.sh
USER		= demo
PASS		= demo
GROUP		= islet
PORT	  = 2222
SIZE		= 2G
NAGIOS		= /usr/local/nagios/libexec
IPTABLES	= /etc/network/if-pre-up.d/iptables-rules
SUDOERS		= /etc/sudoers.d
UPSTART  	= /etc/init
REPO		= $(shell grep url .git/config)
PACKAGE		= deb
Q 		= @
bold   		= $(shell tput bold)
underline 	= $(shell tput smul)
normal 		= $(shell tput sgr0)
red		= $(shell tput setaf 1)
yellow	 	= $(shell tput setaf 3)

default: help

help:
	$(Q)echo "$(bold)ISLET (v$(VERSION)) installation targets:$(normal)"
	$(Q)echo " $(red)install$(normal)                  	- Install and configure islet on the host"
	$(Q)echo " $(red)install-contained$(normal)    		- Install islet as container, with little modification to host"
	$(Q)echo " $(red)uninstall$(normal) 	                - Uninstalls islet ($(yellow)Backup first!$(normal))"
	$(Q)echo " $(red)update$(normal)               		- Update code and reinstall islet"
	$(Q)echo " $(red)mrproper$(normal)                     	- Remove all files not in source distribution"
	$(Q)echo "$(bold)System configuration targets$(bold):$(normal)"
	$(Q)echo " $(red)install-docker$(normal)               	- Install docker ($(normal)$(yellow)Debian/Ubuntu only$(normal))"
	$(Q)echo " $(red)docker-config$(normal)                  - Configure docker storage backend ($(normal)$(yellow)Debian/Ubuntu only$(normal))($(red)Unstable$(normal))"
	$(Q)echo " $(red)user-config$(normal)               	- Configure demo user for islet"
	$(Q)echo " $(red)security-config$(normal)               	- Configure security controls (sshd_config)"
	$(Q)echo " $(red)iptables-config$(normal)               	- Install iptables rules (def: /etc/network/if-pre-up.d/)"
	$(Q)echo "$(bold)Miscellaneous targets:$(normal)"
	$(Q)echo " $(red)install-brolive-config$(normal)        	- Install and configure Brolive image"
	$(Q)echo " $(red)install-nagios-plugin$(normal)        	- Install ISLET Nagios plugin (def: /usr/local/nagios/libexec)"
	$(Q)echo " $(red)template$(normal)                       - Print ISLET config template to stdout"
	$(Q)echo " $(red)package$(normal)                        - Create package from an ISLET installation (def: deb)"
	$(Q)echo " $(red)logo$(normal)                         	- Print logo to stdout"

install: install-files configuration

install-contained:
	$(Q)echo " $(yellow)Installing $(PROG)$(normal)"
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o root -g root -m 644 config/islet.conf $(CONFIG_DIR)/$(PROG).conf
	sed -i "s|ISLETVERS|$(VERSION)|" $(CONFIG_DIR)/islet.conf
	sed -i "s|USERACCOUNT|$(USER)|g" $(CONFIG_DIR)/islet.conf
	install -o root -g root -m 644 config/security.conf $(CONFIG_DIR)/security.conf
	docker run -d --name="islet" \
								-v /usr/bin/docker:/usr/bin/docker:ro \
								-v /var/lib/docker/:/var/lib/docker:rw \
								-v /sbin/iptables:/sbin/iptables:ro \
								-v /sbin/sysctl:/sbin/sysctl:ro \
								-v /exercises:/exercises:ro \
								-v /etc/islet:/etc/islet:ro \
								-v /var/run/docker.sock:/var/run/docker.sock \
								--cap-add=NET_ADMIN \
								-p $(PORT):22 jonschipp/islet
	install -o root -g root -m 644 config/islet.upstart $(UPSTART)/islet.conf
	$(Q)echo " $(bold)--> Connect to ISLET on $(normal)$(underline)SSH port $(PORT)$(normal)"

install-files:
	$(Q)echo " $(yellow)Installing $(PROG)$(normal)"
	mkdir -m 755 -p $(CONFIG_DIR)
	mkdir -m 755 -p $(LIB_DIR)
	mkdir -m 755 -p $(CRON_DIR)
	mkdir -m 755 -p $(BIN_DIR)
	mkdir -m 755 -p $(PLUGIN_DIR)
	install -o root -g root -m 644 config/islet.conf $(CONFIG_DIR)/$(PROG).conf
	install -o root -g root -m 644 config/security.conf $(CONFIG_DIR)/security.conf
	install -o root -g root -m 644 config/1-restart.conf $(CONFIG_DIR)/1-restart.conf
	install -o root -g root -m 644 config/2-del_user.conf $(CONFIG_DIR)/2-del_user.conf
	install -o root -g root -m 644 config/3-del_training.conf $(CONFIG_DIR)/3-del_training.conf
	install -o root -g root -m 644 config/4-clear.conf $(CONFIG_DIR)/4-clear.conf
	install -o root -g root -m 644 lib/libislet $(LIB_DIR)/libislet
	install -o root -g root -m 755 bin/islet_shell $(BIN_DIR)/$(PROG)_shell
	install -o root -g root -m 755 bin/islet_login $(BIN_DIR)/$(PROG)_login
	install -o root -g root -m 644 cron/islet.crontab $(CRON)/$(PROG)
	install -o root -g root -m 750 cron/remove_old_containers $(CRON_DIR)/remove_old_containers
	install -o root -g root -m 750 cron/remove_old_users $(CRON_DIR)/remove_old_users
	install -o root -g root -m 750 cron/disk_limit $(CRON_DIR)/disk_limit
	install -o root -g root -m 750 cron/port_forward $(CRON_DIR)/port_forward
	install -o root -g root -m 744 plugins/restart $(PLUGIN_DIR)/restart
	install -o root -g root -m 744 plugins/del_user $(PLUGIN_DIR)/del_user
	install -o root -g root -m 744 plugins/del_container $(PLUGIN_DIR)/del_container
	install -o root -g root -m 744 plugins/clear $(PLUGIN_DIR)/clear
	install -o root -g root -m 644 docs/islet.5 $(MAN_DIR)/man5/islet.5
	install -o root -g root -m 440 config/islet.sudoers $(SUDOERS)/islet
	$(Q)echo " $(bold)--> Configuration directory is$(normal) $(underline)$(CONFIG_DIR)$(normal)"
	$(Q)echo " $(bold)--> Install directory is$(normal) $(underline)$(INSTALL_DIR)$(normal)"

configuration:
	$(Q)echo " $(yellow)Post-install configuration$(normal)"
	sed -i "s|ISLETVERS|$(VERSION)|" $(CONFIG_DIR)/islet.conf
	sed -i "s|USERACCOUNT|$(USER)|g" $(CONFIG_DIR)/islet.conf
	visudo -c
	sed -i "s|LOCATION|$(CRON_DIR)|g" $(CRON)/$(PROG)
	sed -i "s|LOCATION|$(CONFIG_DIR)/$(PROG).conf|g" $(BIN_DIR)/* $(CRON_DIR)/*
	test -d /var/lib/docker && chown root:$(GROUP) /var/lib/docker /var/lib/docker/repositories-* || true
	test -d /var/lib/docker && chmod g+x /var/lib/docker || true
	test -d /var/lib/docker && chmod g+r /var/lib/docker/repositories-* || true

uninstall:
	$(Q)echo " $(yellow)Uninstalling $(PROG)$(normal)"
	rm -rf $(CONFIG_DIR)
	rm -rf $(INSTALL_DIR)
	rm -f $(CRON)/$(PROG)
	rm -f /var/tmp/$(PROG)_db
	rm -f /etc/security/limits.d/islet.conf
	rm -f $(SUDOERS)/islet
	rm -f $(MAN_DIR)/man5/islet.5
	fgrep -q $(USER) /etc/passwd && userdel -r $(USER) || true
	fgrep -q $(GROUP) /etc/group && groupdel $(GROUP)  || true

mrproper:
	$(Q)echo " $(yellow)Removing files not in source$(normal)"
	$(Q)git ls-files -o | xargs rm -rf

pull:
	$(Q)echo " $(yellow)Pulling latest code from:$(normal) $(underline)$(REPO)$(normal)"
	$(Q)git checkout master 1>/dev/null 2>/dev/null
	$(Q)git pull

update: pull
	$(Q)echo " $(yellow)Installing latest code$(normal)"
	make install

install-brolive-config:
	$(FUNCTIONS) install_sample_configuration
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o root -g root -m 644 extra/brolive.conf $(CONFIG_DIR)/brolive.conf
	$(Q)echo " $(yellow)Try it out: ssh demo@<ip>$(normal)"

install-sample-nsm: install-sample-nsm-configs
	$(FUNCTIONS) install_nsm_configurations
	$(Q)echo " $(yellow)Try it out: ssh demo@<ip>$(normal)"

install-sample-nsm-configs:
	mkdir -m 755 -p $(CONFIG_DIR)
	install -o root -g root -m 644 extra/brolive.conf $(CONFIG_DIR)/brolive.conf
	install -o root -g root -m 644 extra/ids.conf $(CONFIG_DIR)/ids.conf
	install -o root -g root -m 644 extra/argus.conf $(CONFIG_DIR)/argus.conf
	install -o root -g root -m 644 extra/tcpdump.conf $(CONFIG_DIR)/tcpdump.conf
	install -o root -g root -m 644 extra/netsniff-ng.conf $(CONFIG_DIR)/netsniff-ng.conf
	install -o root -g root -m 644 extra/volatility.conf $(CONFIG_DIR)/volatility.conf
	install -o root -g root -m 644 extra/sagan.conf $(CONFIG_DIR)/sagan.conf

install-sample-distros:
	$(FUNCTIONS) install_sample_distributions
	mkdir -m 755 -p $(CONFIG_DIR)

install-sample-cadvisor:
	docker run -d -v /var/run:/var/run:rw -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro -p 8080:8080 --name="cadvisor" google/cadvisor:latest
	install -o root -g root -m 644 extra/cadvisor.upstart $(UPSTART)/cadvisor.conf

install-docker:
	$(FUNCTIONS) install_docker

docker-config:
	$(FUNCTIONS) docker_configuration $(SIZE)

user-config:
	$(FUNCTIONS) user_configuration $(USER) $(PASS) $(GROUP) $(BIN_DIR)/$(PROG)_shell

security-config:
	$(FUNCTIONS) security_configuration $(USER) $(BIN_DIR)/$(PROG)_shell

bro-training: install user-config security-config install-docker install-brolive-config

iptables-config:
	install -o root -g root -m 750 extra/iptables-rules $(IPTABLES)
	$(IPTABLES)

install-nagios-plugin:
	install -o root -g nagios -m 550 extra/check_islet.sh $(NAGIOS)/check_islet.sh

package:
	$(Q)! command -v fpm 1>/dev/null && echo "$(yellow)fpm is not installed or in PATH, try \`\`gem install fpm''.$(normal)" \
	|| fpm -s dir -t $(PACKAGE) -n "islet" -v $(VERSION) /etc/islet /opt/islet \

logo:
	$(FUNCTIONS) logo

template:
	$(Q) $(FUNCTIONS) template

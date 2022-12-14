DEPLOY_NAME=snake

info:
	echo "make deploy       - deploy to http://rpi.memention.net/$(DEPLOY_NAME)/"
	echo "make deploy-dirty - deploy w/o checking dirty repo"
	echo "make open         - open http://rpi.memention.net/$(DEPLOY_NAME)/"
	echo "make reset        - flutter clean + pub get"

.SILENT:

.PHONY: info deploy deploy-dirty dirty open

deploy: dirty deploy-dirty

deploy-dirty:
	flutter clean
	chmod -R a+r assets
	rm -rf build/$(DEPLOY_NAME) build/$(DEPLOY_NAME).zip
	flutter build web --base-href /$(DEPLOY_NAME)/ --release
	cd build ; mv web $(DEPLOY_NAME) ; zip -r $(DEPLOY_NAME).zip $(DEPLOY_NAME)
	scp build/$(DEPLOY_NAME).zip rpi.memention.net:
	ssh rpi.memention.net ./deploy.sh $(DEPLOY_NAME)

reset:
	flutter clean
	flutter pub get

dirty:
	if [[ `git status -s` == "" ]] ; then echo "Repo is clean" ; else echo "Repo is dirty" ; exit -1 ; fi

open:
	open http://rpi.memention.net/$(DEPLOY_NAME)/

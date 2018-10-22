all:
	$(MAKE) -C packages all
	(cd terraform && bash -c "terraform apply -var-file=<(pass infra/terraform)")

.PHONY: all

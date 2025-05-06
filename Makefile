-include .env
build:; forge build

deploy-sepolia:; forge script script/DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE-KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
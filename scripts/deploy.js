async function main() {
    const ContractFactory = await ethers.getContractFactory("LevelUpsToken");
    const contract = await ContractFactory.deploy();
    console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
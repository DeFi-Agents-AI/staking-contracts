import { ethers } from "hardhat";

async function main() {
  const stakingTokenAddress = process.env.STAKING_TOKEN_ADDRESS!;

  const StakingContract = await ethers.getContractFactory("StakingContract");

  const stakingContract = await StakingContract.deploy(stakingTokenAddress);

  await stakingContract.waitForDeployment();

  console.log("StakingContract deployed to:", await stakingContract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

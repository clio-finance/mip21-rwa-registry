// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import {RwaRegistry} from "./RwaRegistry.sol";

contract RwaRegistryTest is Test {
  RwaRegistry internal reg;

  function setUp() public {
    reg = new RwaRegistry();
  }

  /*//////////////////////////////////
              Authorization
  //////////////////////////////////*/

  function testRely() public {
    reg.rely(address(0x1337));

    assertEq(reg.wards(address(0x1337)), 1);
  }

  function testDeny() public {
    reg.deny(address(this));

    assertEq(reg.wards(address(this)), 0);
  }

  /*//////////////////////////////////
     Supported Components Management
  //////////////////////////////////*/

  function testAddDefaultSupportedComponentsDuringDeployment() public {
    assertEq(reg.listSupportedComponents().length, 5);
    assertEq(reg.isSupportedComponent("urn"), 1);
    assertEq(reg.isSupportedComponent("liquidationOracle"), 1);
    assertEq(reg.isSupportedComponent("outputConduit"), 1);
    assertEq(reg.isSupportedComponent("inputConduit"), 1);
    assertEq(reg.isSupportedComponent("jar"), 1);
  }

  function testAddSupportedComponent() public {
    reg.addSupportedComponent("somethingElse");

    assertEq(reg.isSupportedComponent("somethingElse"), 1);
  }

  function testRevertAddExistingSupportedComponent() public {
    // bytes32 componentName_

    bytes32 componentName_ = "anything";
    reg.addSupportedComponent(componentName_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.ComponentAlreadySupported.selector, componentName_));
    reg.addSupportedComponent(componentName_);
  }

  function testRevertUnautorizedAddSupportedComponent() public {
    // address sender_
    // if (sender_ == address(this)) {
    //   return;
    // }
    address sender_ = address(0x1337);

    vm.expectRevert(RwaRegistry.Unauthorized.selector);
    vm.prank(sender_);

    reg.addSupportedComponent("anything");
  }

  /*//////////////////////////////////
     Deals & Components Management
  //////////////////////////////////*/

  function testAddDealAndComponents() public {
    // bytes32 ilk_,
    // address urn_,
    // address liquidationOracle_,
    // address outputConduit_,
    // address inputConduit_,
    // address jar_

    bytes32 ilk_ = "RWA1337-a";
    address urn_ = address(0x2448);
    address liquidationOracle_ = address(0x3559);
    address outputConduit_ = address(0x466a);
    address inputConduit_ = address(0x577b);
    address jar_ = address(0x688c);

    bytes32[] memory names = new bytes32[](5);
    names[0] = "urn";
    names[1] = "liquidationOracle";
    names[2] = "outputConduit";
    names[3] = "inputConduit";
    names[4] = "jar";

    address[] memory addrs = new address[](5);
    addrs[0] = urn_;
    addrs[1] = liquidationOracle_;
    addrs[2] = outputConduit_;
    addrs[3] = inputConduit_;
    addrs[4] = jar_;

    uint88[] memory variants = new uint88[](5);
    variants[0] = 1;
    variants[1] = 1;
    variants[2] = 1;
    variants[3] = 1;
    variants[4] = 1;

    reg.add(ilk_, names, addrs, variants);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
    (bytes32[] memory actualNames, address[] memory actualAddrs, uint88[] memory actualVariants) = reg.listComponentsOf(
      ilk_
    );

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

    assertEq(actualNames[0], names[0], "Component mismatch: urn");
    assertEq(actualNames[1], names[1], "Component mismatch: liquidationOracle");
    assertEq(actualNames[2], names[2], "Component mismatch: outputConduit");
    assertEq(actualNames[3], names[3], "Component mismatch: inputConduit");
    assertEq(actualNames[4], names[4], "Component mismatch: jar");

    assertEq(actualAddrs[0], addrs[0], "Component address mismatch: urn");
    assertEq(actualAddrs[1], addrs[1], "Component address mismatch: liquidationOracle");
    assertEq(actualAddrs[2], addrs[2], "Component address mismatch: outputConduit");
    assertEq(actualAddrs[3], addrs[3], "Component address mismatch: inputConduit");
    assertEq(actualAddrs[4], addrs[4], "Component address mismatch: jar");

    assertEq(actualVariants[0], variants[0], "Component variant mismatch: urn");
    assertEq(actualVariants[1], variants[1], "Component variant mismatch: liquidationOracle");
    assertEq(actualVariants[2], variants[2], "Component variant mismatch: outputConduit");
    assertEq(actualVariants[3], variants[3], "Component variant mismatch: inputConduit");
    assertEq(actualVariants[4], variants[4], "Component variant mismatch: jar");
  }

  function testRevertAddDealWithUnsupportedComponent() public {
    // bytes32 ilk_,
    // address urn_,
    // address someAddr,

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x1337);
    address someAddr_ = address(0x2448);

    bytes32[] memory names = new bytes32[](5);
    names[0] = "urn";
    names[1] = "something";

    address[] memory addrs = new address[](5);
    addrs[0] = urn_;
    addrs[1] = someAddr_;

    uint88[] memory variants = new uint88[](5);
    variants[0] = 1;
    variants[1] = 1;

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.UnsupportedComponent.selector, names[1]));
    reg.add(ilk_, names, addrs, variants);
  }

  function testRevertAddDealWithComponentsWithMismatchingParams() public {
    // bytes32 ilk_,
    // address urn_
    // address liquidationOracle_,

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x1337);
    address liquidationOracle_ = address(0x2448);

    bytes32[] memory names = new bytes32[](1);
    names[0] = "urn";

    address[] memory addrs = new address[](2);
    addrs[0] = urn_;
    addrs[1] = liquidationOracle_;

    uint88[] memory variants = new uint88[](2);
    variants[0] = 1;
    variants[1] = 1;

    vm.expectRevert(RwaRegistry.MismatchingComponentParams.selector);
    reg.add(ilk_, names, addrs, variants);
  }

  function testRevertListComponentsOfUnexistingDeal() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, ilk_));
    reg.listComponentsOf(ilk_);
  }

  function testAddDealWithEmptyComponentList() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    bytes32[] memory names;
    address[] memory addrs;
    uint88[] memory variants;
    reg.add(ilk_, names, addrs, variants);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
    (bytes32[] memory actualNames, address[] memory actualAddrs, uint88[] memory actualVariants) = reg.listComponentsOf(
      ilk_
    );

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));
    assertEq(actualNames.length, 0, "Name list is not empty");
    assertEq(actualAddrs.length, 0, "Address list is not empty");
    assertEq(actualVariants.length, 0, "Variant list is not empty");
  }

  function testListAllDealComponentNames() public {
    // bytes32 ilk_,
    // addrres urn_,
    // addrres liquidationOracle_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x1337);
    address liquidationOracle_ = address(0x2448);

    bytes32[] memory originalNames = new bytes32[](2);
    address[] memory originalAddrs = new address[](2);
    uint88[] memory originalVariants = new uint88[](2);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    originalNames[1] = "liquidationOracle";
    originalAddrs[1] = liquidationOracle_;
    originalVariants[1] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    bytes32[] memory actualNames = reg.listComponentNamesOf(ilk_);

    assertEq(actualNames[0], originalNames[0]);
    assertEq(actualNames[1], originalNames[1]);
  }

  function testRevertListComponentNamesOfUnexistingDeal() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, ilk_));
    reg.listComponentNamesOf(ilk_);
  }

  function testAddDealWithNoComponents() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    reg.add(ilk_);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

    (bytes32[] memory names, address[] memory addrs, uint88[] memory variants) = reg.listComponentsOf(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));
    assertEq(names.length, 0, "Name list is not empty");
    assertEq(addrs.length, 0, "Address list is not empty");
    assertEq(variants.length, 0, "Variant list is not empty");
  }

  function testRevertAddExistingDeal() public {
    // bytes32 ilk_,

    bytes32 ilk_ = "RWA1337-A";
    reg.add(ilk_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealAlreadyExists.selector, ilk_));
    reg.add(ilk_);
  }

  function testRevertUnautorizedAddDeal() public {
    // address sender_,
    // bytes32 ilk_,

    // if (sender_ == address(this)) {
    //   return;
    // }

    address sender_ = address(0x1337);
    bytes32 ilk_ = "RWA1337-A";

    vm.expectRevert(RwaRegistry.Unauthorized.selector);
    vm.prank(sender_);

    reg.add(ilk_);
  }

  function testListAllDealIlks() public {
    // bytes32 ilk0_, bytes32 ilk1_
    // vm.assume(ilk0_ != ilk1_);

    bytes32 ilk0_ = "RWA1337-A";
    bytes32 ilk1_ = "RWA2448-A";

    reg.add(ilk0_);
    reg.add(ilk1_);

    bytes32[] memory actualIlks = reg.list();

    assertEq(actualIlks[0], ilk0_);
    assertEq(actualIlks[1], ilk1_);
  }

  function testCountAllDealIlks() public {
    // bytes32[] memory ilks_
    // if (ilks_.length == 0) {
    //   return;
    // }

    bytes32[] memory ilks_ = new bytes32[](3);
    ilks_[0] = "RWA1337-A";
    ilks_[1] = "RWA2448-A";
    ilks_[2] = "RWA3559-A";

    uint256 duplicates = 0;
    for (uint256 i = 0; i < ilks_.length; i++) {
      try reg.add(ilks_[i]) {} catch {
        duplicates++;
      }
    }

    uint256 count = reg.count();

    uint256 expected = ilks_.length - duplicates;
    assertEq(count, expected, "Wrong count");
  }

  function testAddNewComponentToDeal() public {
    // bytes32 ilk_,
    // address urn_,
    // uint88 variant_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    uint88 variant_ = 0x2830;
    reg.add(ilk_);

    reg.file(ilk_, "component", "urn", urn_, variant_);

    (address addr, uint88 variant) = reg.getComponent(ilk_, "urn");
    assertEq(addr, urn_, "Component address mismatch");
    assertEq(variant, variant_, "Component variant mismatch");
  }

  function testUpdateDealComponent() public {
    // bytes32 ilk_,
    // address urn_,
    // uint88 variant_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);

    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    uint88 variant_ = 0x2830;
    reg.file(ilk_, "component", "urn", urn_, variant_);

    (, uint88 updatedVariant) = reg.getComponent(ilk_, "urn");
    assertEq(updatedVariant, variant_, "Component variant mismatch");
  }

  function testReverGetComponentForUnexistingDeal() public {
    // bytes32 ilk_,
    // address urn_,
    // uint88 variant_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    bytes32 wrongIlk = "RWA2448-A";
    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, wrongIlk));
    reg.getComponent(wrongIlk, "urn");
  }

  function testRevertGetUnexistentComponentForExistingDeal() public {
    // bytes32 ilk_,
    // address urn_,
    // uint88 variant_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    vm.expectRevert(
      abi.encodeWithSelector(RwaRegistry.ComponentDoesNotExist.selector, ilk_, bytes32("liquidationOracle"))
    );
    reg.getComponent(ilk_, "liquidationOracle");
  }

  function testReverUpdateUnexistingParameter() public {
    // bytes32 ilk_,
    // address urn_,
    // uint88 variant_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x2448);
    uint88 variant_ = 0x2830;
    reg.add(ilk_);

    vm.expectRevert(
      abi.encodeWithSelector(RwaRegistry.UnsupportedParameter.selector, ilk_, bytes32("unexistingParameter"))
    );
    reg.file(ilk_, "unexistingParameter", "urn", urn_, variant_);
  }

  function testRevertUnautorizedUpdateDeal() public {
    // address sender_,
    // bytes32 ilk_,
    // address urn_

    // if (sender_ == address(this)) {
    //   return;
    // }

    address sender_ = address(0x1337);
    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    vm.expectRevert(RwaRegistry.Unauthorized.selector);
    vm.prank(sender_);

    reg.file(ilk_, "component", "urn", address(0x1337), 1337);
  }

  function testFinalizeComponent() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    reg.finalize(ilk_);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.FINALIZED));
  }

  function testRevertFinalizeUnexistingComponent() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);

    bytes32 wrongIlk = "RWA2448-A";
    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealIsNotActive.selector, wrongIlk));
    reg.finalize(wrongIlk);
  }

  function testRevertUpdateFinalizedComponent() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";
    address urn_ = address(0x3549);
    bytes32[] memory originalNames = new bytes32[](1);
    address[] memory originalAddrs = new address[](1);
    uint88[] memory originalVariants = new uint88[](1);
    originalNames[0] = "urn";
    originalAddrs[0] = urn_;
    originalVariants[0] = 1;
    reg.add(ilk_, originalNames, originalAddrs, originalVariants);
    reg.finalize(ilk_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealIsNotActive.selector, ilk_));
    reg.file(ilk_, "component", "urn", address(0x2448), 2);
  }
}

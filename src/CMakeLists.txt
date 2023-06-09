
add_definitions(-DSTATICLIB)

include_directories(${CMAKE_SOURCE_DIR}/external/linenoise)

file(GLOB_RECURSE BlockchainExplorer BlockchainExplorer/*)
file(GLOB_RECURSE Common Common/*)
file(GLOB_RECURSE Crypto crypto/*)
file(GLOB_RECURSE CryptoNoteCore CryptoNoteCore/* CryptoNoteConfig.h)
file(GLOB_RECURSE CryptoNoteProtocol CryptoNoteProtocol/*)
file(GLOB_RECURSE Daemon Daemon/*)
file(GLOB_RECURSE Http HTTP/*)
file(GLOB_RECURSE InProcessNode InProcessNode/*)
file(GLOB_RECURSE Logging Logging/*)
file(GLOB_RECURSE NodeRpcProxy NodeRpcProxy/*)
file(GLOB_RECURSE Optimizer Optimizer/*)
file(GLOB_RECURSE P2p P2p/*)
file(GLOB_RECURSE Rpc Rpc/*)
file(GLOB_RECURSE Serialization Serialization/*)
file(GLOB_RECURSE SimpleWallet SimpleWallet/*)
file(GLOB_RECURSE Mnemonics Mnemonics/*)
file(GLOB_RECURSE Transfers Transfers/*)
file(GLOB_RECURSE Wallet Wallet/*)
file(GLOB_RECURSE WalletLegacy WalletLegacy/*)
file(GLOB_RECURSE JsonRpcServer JsonRpcServer/*)
file(GLOB_RECURSE PaymentGate PaymentGate/*)
file(GLOB_RECURSE PaymentGateService PaymentGateService/*)
file(GLOB_RECURSE Miner Miner/*)
file(GLOB_RECURSE GreenWallet GreenWallet/*)

if (MSVC)
  file(GLOB_RECURSE System System/* Platform/Windows/System/*)
elseif (APPLE)
  file(GLOB_RECURSE System System/* Platform/OSX/System/* Platform/Posix/System/*)
elseif (FREEBSD)
  file(GLOB_RECURSE System System/* Platform/FreeBSD/System/* Platform/Posix/System/*)
elseif (ANDROID)
  file(GLOB_RECURSE System System/* Platform/Android/System/* Platform/Posix/System/*)
else()
  file(GLOB_RECURSE System System/* Platform/Linux/System/* Platform/Posix/System/*)
endif()

source_group("" FILES $${Common} ${Crypto} ${CryptoNoteCore} ${CryptoNoteProtocol} ${Daemon} ${GreenWallet} ${Http} ${JsonRpcServer} ${Logging} ${Mnemonics} ${NodeRpcProxy} ${Optimizer} ${P2p} ${Rpc} ${Serialization} ${SimpleWallet} ${System} ${Transfers} ${Wallet} ${WalletLegacy})

add_library(BlockchainExplorer ${BlockchainExplorer})
add_library(CryptoNoteProtocol ${CryptoNoteProtocol})
add_library(Common ${Common})
add_library(Crypto ${Crypto})
add_library(CryptoNoteCore ${CryptoNoteCore})
add_library(Http ${Http})
add_library(InProcessNode ${InProcessNode})
add_library(Logging ${Logging})
add_library(Mnemonics ${Mnemonics})
add_library(NodeRpcProxy ${NodeRpcProxy})
add_library(Rpc ${Rpc})
add_library(P2P ${P2p})
add_library(Serialization ${Serialization})
add_library(System ${System})
add_library(Transfers ${Transfers})
add_library(Wallet ${Wallet} ${WalletLegacy})
add_library(PaymentGate ${PaymentGate})
add_library(JsonRpcServer ${JsonRpcServer})

list(APPEND luckycoinCommon Common)
list(APPEND luckycoinCore Rpc Http CryptoNoteCore Logging Serialization Crypto System)
list(APPEND luckycoinWallet Wallet Transfers NodeRpcProxy)
list(APPEND luckycoinLink CryptoNoteProtocol P2P BlockchainExplorer)
list(APPEND luckycoinPaymentGate PaymentGate JsonRpcServer InProcessNode)

if (MSVC)
  add_executable(Daemon ${Daemon} BinaryInfo/daemon.rc)
  add_executable(SimpleWallet ${SimpleWallet} BinaryInfo/simplewallet.rc)
  add_executable(GreenWallet ${GreenWallet} BinaryInfo/greenwallet.rc)
  add_executable(Optimizer ${Optimizer} BinaryInfo/optimizer.rc)
  add_executable(PaymentGateService ${PaymentGateService} BinaryInfo/walletd.rc)
  add_executable(Miner ${Miner} BinaryInfo/miner.rc)
else()
  add_executable(Daemon ${Daemon})
  add_executable(SimpleWallet ${SimpleWallet})
  add_executable(GreenWallet ${GreenWallet})
  add_executable(Optimizer ${Optimizer})
  add_executable(PaymentGateService ${PaymentGateService})
  add_executable(Miner ${Miner})
endif()

target_link_libraries(Daemon ${luckycoinCore} ${luckycoinLink} ${luckycoinCommon} upnpc-static ${Boost_LIBRARIES})
target_link_libraries(SimpleWallet ${luckycoinWallet} ${luckycoinCore} Mnemonics ${luckycoinCommon} ${Boost_LIBRARIES})
target_link_libraries(GreenWallet ${luckycoinWallet} ${luckycoinCore} Mnemonics ${luckycoinCommon} ${Boost_LIBRARIES})
target_link_libraries(Optimizer PaymentGate ${luckycoinCore} ${luckycoinCommon} ${Boost_LIBRARIES})
target_link_libraries(PaymentGateService ${luckycoinPaymentGate} ${luckycoinWallet} ${luckycoinCore}
                      ${luckycoinLink} ${luckycoinCommon} upnpc-static ${Boost_LIBRARIES})
target_link_libraries(Miner ${luckycoinCore} ${luckycoinCommon} ${Boost_LIBRARIES})

if (MSVC)
  target_link_libraries(System ws2_32)
  target_link_libraries(Daemon Rpcrt4)
  target_link_libraries(SimpleWallet Rpcrt4)
  target_link_libraries(PaymentGateService Rpcrt4)
else()
  target_link_libraries(Daemon ${EXTRA_LIBRARIES})
  target_link_libraries(SimpleWallet ${EXTRA_LIBRARIES})
  target_link_libraries(GreenWallet ${EXTRA_LIBRARIES})
  target_link_libraries(Optimizer ${EXTRA_LIBRARIES})
  target_link_libraries(PaymentGateService ${EXTRA_LIBRARIES})
  target_link_libraries(Miner ${EXTRA_LIBRARIES})
endif()

if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux" OR APPLE AND NOT ANDROID)
  target_link_libraries(SimpleWallet -lresolv)
  target_link_libraries(Daemon -lresolv)
  target_link_libraries(PaymentGateService -lresolv)
  target_link_libraries(GreenWallet -lresolv)
endif()

if (FREEBSD)
  target_link_libraries(SimpleWallet -lthr)
  target_link_libraries(Daemon -lthr)
  target_link_libraries(PaymentGateService -lthr)
  target_link_libraries(Miner -lthr)
  target_link_libraries(GreenWallet -lthr)
endif()

add_dependencies(P2P version)
add_dependencies(Rpc version)
add_dependencies(PaymentGate version)
add_dependencies(CryptoNoteCore version)
add_dependencies(InProcessNode version)

set_property(TARGET Daemon PROPERTY OUTPUT_NAME "luckycoind")
set_property(TARGET SimpleWallet PROPERTY OUTPUT_NAME "simplewallet")
set_property(TARGET GreenWallet PROPERTY OUTPUT_NAME "greenwallet")
set_property(TARGET Optimizer PROPERTY OUTPUT_NAME "optimizer")
set_property(TARGET PaymentGateService PROPERTY OUTPUT_NAME "walletd")
set_property(TARGET Miner PROPERTY OUTPUT_NAME "miner")


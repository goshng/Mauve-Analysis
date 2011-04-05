cmake_minimum_required(VERSION 2.8)
PROJECT (warg)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}")

find_package(GSL REQUIRED)
include_directories(${GSL_INCLUDE_DIRS} ${GSLCBLAS_INCLUDE_DIRS})
set(LIBS ${LIBS} ${GSL_LIBRARIES} ${GSLCBLAS_LIBRARIES})

# target_link_libraries(${LIBS})
link_libraries(${LIBS})

SET (WARG_SRCS 
  data.cpp
  data.h
  exponential.h
  metropolis.cpp
  metropolis.h
  move.cpp
  move.h
  moveaddedge.cpp
  moveaddedge.h
  moveageclonal.cpp
  moveageclonal.h
  movedelta.cpp
  movedelta.h
  moveedgechange.cpp
  moveedgechange.h
  movegreedytree.cpp
  movegreedytree.h
  moveregraftclonal.cpp
  moveregraftclonal.h
  moveremedge.cpp
  moveremedge.h
  moverho.cpp
  moverho.h
  movescaletree.cpp
  movescaletree.h
  movesitechange.cpp
  movesitechange.h
  movetheta.cpp
  movetheta.h
  movetimechange.cpp
  movetimechange.h
  mpiutils.cpp
  mpiutils.h
  node.cpp
  node.h
  param.cpp
  param.h
  recedge.cpp
  recedge.h
  rectree.cpp
  rectree.h
  rng.cpp
  rng.h
  slotallocator.h
  tree.cpp
  tree.h
  wargxml.cpp
  wargxml.h
  weakargsim.cpp
  weakarg.h
)

ADD_EXECUTABLE (warg ${WARG_SRCS})

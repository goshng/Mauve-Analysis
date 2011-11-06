cmake_minimum_required(VERSION 2.8)
PROJECT (gui)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}")

# For Mac
# The following three lines.
find_package(GSL REQUIRED)
include_directories(/opt/local/include /Users/goshng/Documents/Projects/Mauve-Analysis/src/warg/src)
set(LIBS ${LIBS} ${GSL_LIBRARIES} ${GSLCBLAS_LIBRARIES})
##include_directories(${GSL_INCLUDE_DIRS} ${GSLCBLAS_INCLUDE_DIRS} /Users/goshng/Documents/Projects/Mauve-Analysis/src/warg/src)

# For CAC
# The following two lines.
#include_directories(/cac/contrib/gsl-1.12/include /home/fs01/sc2265/run/mauve/101011/bpp/Mauve-Analysis/src/warg/src)
#set(LIBS ${LIBS} /cac/contrib/gsl-1.12/lib/libgsl.a /cac/contrib/gsl-1.12/lib/libgslcblas.a)

# target_link_libraries(${LIBS})
link_libraries(${LIBS})

SET (WARG_SRCS 
 tinystr.cpp
 tinystr.h
 tinyxml.cpp
 tinyxml.h
 tinyxmlerror.cpp
 tinyxmlparser.cpp
 mainwindowimpl.cpp
 gui.cpp
 paramqt.cpp
 heatimpl.cpp
 ../warg/src/rng.cpp
 ../warg/src/wargxml.cpp
 ../warg/src/param.cpp
 ../warg/src/rectree.cpp
 ../warg/src/tree.cpp
 ../warg/src/node.cpp
 ../warg/src/data.cpp
 ../warg/src/recedge.cpp
 outputfile.cpp
 ../warg/src/metropolis.cpp
 ../warg/src/move.cpp
 ../warg/src/movetheta.cpp
 ../warg/src/moveremedge.cpp
 ../warg/src/moveaddedge.cpp
 ../warg/src/movesitechange.cpp
 ../warg/src/movetimechange.cpp
 ../warg/src/moverho.cpp
 ../warg/src/moveedgechange.cpp
 ../warg/src/movedelta.cpp
 ../warg/src/moveageclonal.cpp
 ../warg/src/movescaletree.cpp
 ../warg/src/moveregraftclonal.cpp
 ../warg/src/movegreedytree.cpp
 ../warg/src/mpiutils.cpp
 mainwindowimpl.h
 paramqt.h
 heatimpl.h
 ../warg/src/rng.h
 ../warg/src/wargxml.h
 ../warg/src/param.h
 ../warg/src/rectree.h
 ../warg/src/tree.h
 ../warg/src/node.h
 ../warg/src/rng.h
 ../warg/src/data.h
 ../warg/src/recedge.h
 outputfile.h
 ../warg/src/metropolis.h
 ../warg/src/move.h
 ../warg/src/movetheta.h
 ../warg/src/moveremedge.h
 ../warg/src/moveaddedge.h
 ../warg/src/movesitechange.h
 ../warg/src/movetimechange.h
 ../warg/src/moverho.h
 ../warg/src/moveedgechange.h
 ../warg/src/movedelta.h
 ../warg/src/moveageclonal.h
 ../warg/src/movescaletree.h
 ../warg/src/moveregraftclonal.h
 ../warg/src/movegreedytree.h
 ../warg/src/mpiutils.h
)

ADD_EXECUTABLE (gui ${WARG_SRCS})

#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Environment
MKDIR=mkdir
CP=cp
GREP=grep
NM=nm
CCADMIN=CCadmin
RANLIB=ranlib
CC=gcc
CCC=g++
CXX=g++
FC=gfortran
AS=as

# Macros
CND_PLATFORM=GNU-Linux
CND_DLIB_EXT=so
CND_CONF=Release
CND_DISTDIR=dist
CND_BUILDDIR=build

# Include project Makefile
include Makefile

# Object Directory
OBJECTDIR=${CND_BUILDDIR}/${CND_CONF}/${CND_PLATFORM}

# Object Files
OBJECTFILES= \
	${OBJECTDIR}/_ext/26289040/mkl.o \
	${OBJECTDIR}/_ext/61fe2933/mkl.o \
	${OBJECTDIR}/_ext/1c8aa706/Template.o \
	${OBJECTDIR}/_ext/bfbadf9e/fftw3.o \
	${OBJECTDIR}/_ext/bfbadf9e/fftw3.o \
	${OBJECTDIR}/_ext/bfbadf9e/fftw3l.o \
	${OBJECTDIR}/_ext/bfbadf9e/fftw3q.o \
	${OBJECTDIR}/_ext/7bff708d/gobjectnotifyqueue.o \
	${OBJECTDIR}/main.o \
	${OBJECTDIR}/main2.o


# C Compiler Flags
CFLAGS=

# CC Compiler Flags
CCFLAGS=
CXXFLAGS=

# Fortran Compiler Flags
FFLAGS=

# Assembler Flags
ASFLAGS=

# Link Libraries and Options
LDLIBSOPTIONS=

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/${CND_CONF}/${CND_PLATFORM}/tcc

${CND_DISTDIR}/${CND_CONF}/${CND_PLATFORM}/tcc: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/${CND_CONF}/${CND_PLATFORM}
	${LINK.cc} -o ${CND_DISTDIR}/${CND_CONF}/${CND_PLATFORM}/tcc ${OBJECTFILES} ${LDLIBSOPTIONS}

${OBJECTDIR}/_ext/26289040/mkl.o: /opt/cuda/include/cusplibrary-develop/performance/mkl/mkl.c
	${MKDIR} -p ${OBJECTDIR}/_ext/26289040
	${RM} "$@.d"
	$(COMPILE.c) -O2 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/_ext/26289040/mkl.o /opt/cuda/include/cusplibrary-develop/performance/mkl/mkl.c

${OBJECTDIR}/_ext/61fe2933/mkl.o: /opt/cuda/include/performance/mkl/mkl.c
	${MKDIR} -p ${OBJECTDIR}/_ext/61fe2933
	${RM} "$@.d"
	$(COMPILE.c) -O2 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/_ext/61fe2933/mkl.o /opt/cuda/include/performance/mkl/mkl.c

${OBJECTDIR}/_ext/1c8aa706/Template.o: /usr/include/X11/Xaw/Template.c
	${MKDIR} -p ${OBJECTDIR}/_ext/1c8aa706
	${RM} "$@.d"
	$(COMPILE.c) -O2 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/_ext/1c8aa706/Template.o /usr/include/X11/Xaw/Template.c

${OBJECTDIR}/_ext/bfbadf9e/fftw3.o: /usr/include/fftw3.f
	${MKDIR} -p ${OBJECTDIR}/_ext/bfbadf9e
	$(COMPILE.f) -O2 -o ${OBJECTDIR}/_ext/bfbadf9e/fftw3.o /usr/include/fftw3.f

${OBJECTDIR}/_ext/bfbadf9e/fftw3.o: /usr/include/fftw3.f03
	${MKDIR} -p ${OBJECTDIR}/_ext/bfbadf9e
	$(COMPILE.f) -O2 -o ${OBJECTDIR}/_ext/bfbadf9e/fftw3.o /usr/include/fftw3.f03

${OBJECTDIR}/_ext/bfbadf9e/fftw3l.o: /usr/include/fftw3l.f03
	${MKDIR} -p ${OBJECTDIR}/_ext/bfbadf9e
	$(COMPILE.f) -O2 -o ${OBJECTDIR}/_ext/bfbadf9e/fftw3l.o /usr/include/fftw3l.f03

${OBJECTDIR}/_ext/bfbadf9e/fftw3q.o: /usr/include/fftw3q.f03
	${MKDIR} -p ${OBJECTDIR}/_ext/bfbadf9e
	$(COMPILE.f) -O2 -o ${OBJECTDIR}/_ext/bfbadf9e/fftw3q.o /usr/include/fftw3q.f03

${OBJECTDIR}/_ext/7bff708d/gobjectnotifyqueue.o: /usr/include/glib-2.0/gobject/gobjectnotifyqueue.c
	${MKDIR} -p ${OBJECTDIR}/_ext/7bff708d
	${RM} "$@.d"
	$(COMPILE.c) -O2 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/_ext/7bff708d/gobjectnotifyqueue.o /usr/include/glib-2.0/gobject/gobjectnotifyqueue.c

${OBJECTDIR}/main.o: main.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -O2 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/main.o main.cpp

${OBJECTDIR}/main2.o: main2.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -O2 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/main2.o main2.cpp

# Subprojects
.build-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${CND_BUILDDIR}/${CND_CONF}
	${RM} *.mod

# Subprojects
.clean-subprojects:

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc

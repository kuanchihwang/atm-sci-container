# Template make include file for building LAPACK.

CC = $(SELECTED_CC)
CFLAGS = $(SELECTED_CFLAGS)

ifeq ($(findstring gcc,$(COMPILER)),gcc)
    ADDITIONAL_FCFLAGS = -fno-unsafe-math-optimizations -frounding-math -fsignaling-nans -frecursive
else ifeq ($(findstring intel,$(COMPILER)),intel)
    ADDITIONAL_FCFLAGS = -fp-model=precise -assume recursion
else
    ADDITIONAL_FCFLAGS =
endif

FC = $(SELECTED_FC)
FFLAGS = $(strip $(SELECTED_FCFLAGS) $(ADDITIONAL_FCFLAGS))
FFLAGS_DRV = $(FFLAGS)
FFLAGS_NOOPT = $(strip $(filter-out -O%,$(SELECTED_FCFLAGS)) -O0 $(ADDITIONAL_FCFLAGS))

AR = ar
ARFLAGS = cr
RANLIB = ranlib

BUILD_DEPRECATED = 1

ifeq ($(findstring gcc,$(COMPILER)),gcc)
    TIMER = INT_ETIME
else
    TIMER = EXT_ETIME
endif

BLASLIB    = $(TOPSRCDIR)/libblas.a
CBLASLIB   = $(TOPSRCDIR)/libcblas.a
LAPACKLIB  = $(TOPSRCDIR)/liblapack.a
LAPACKELIB = $(TOPSRCDIR)/liblapacke.a
TMGLIB     = $(TOPSRCDIR)/libtmg.a

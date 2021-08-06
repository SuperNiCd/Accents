%module Accents_libAccents
%include <od/glue/mod.cpp.swig>

%{

#undef SWIGLUA

#include </home/joe/Accents/Accents/VoltageVault.h>
#include </home/joe/Accents/Accents/Maths.h>
#include </home/joe/Accents/Accents/PointsEG.h>
#include </home/joe/Accents/Accents/Bitwise.h>

	
#define SWIGLUA

%}

%include </home/joe/Accents/Accents/VoltageVault.h>
%include </home/joe/Accents/Accents/Maths.h>
%include </home/joe/Accents/Accents/PointsEG.h>
%include </home/joe/Accents/Accents/Bitwise.h>

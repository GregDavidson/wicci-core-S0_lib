# Wicci Project; module makefile; requires GNU Make.
# Copyright (c) 2005 - 2010, J. Greg Davidson.
# You may use this file under the terms of the
# GNU AFFERO GENERAL PUBLIC LICENSE 3.0
# as specified in the file LICENSE.md included with this distribution.
# All other use requires my permission in writing.

include ../Makefile.wicci
# The extension system obsoletes share/contrib
# Now there's share/extension
# but maybe we don't need it?? Let's try and see!!
# vpath %.sql /usr/local/SW/pgsql/share/contrib
all: $(DepMakes) $(SchemaOut)
-include $(DepMakes)

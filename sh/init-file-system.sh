###############################################################################
# Copyright (C) 2011 Sang Chul Choi
#
# This file is part of Mauve Analysis.
# 
# Mauve Analysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mauve Analysis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mauve Analysis.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
function init-file-system {
  echo -n "Creating $MAUVEANALYSISDIR/output ..." 
  mkdir $MAUVEANALYSISDIR/output 
  echo -e " done"
  echo -n "Creating $MAUVEANALYSISDIR/input ..." 
  mkdir $MAUVEANALYSISDIR/input 
  echo -e " done"
  echo -n "Creating $CAC_ROOT/output at $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir -p $CAC_ROOT/output
  echo -e " done"
  echo -n "Creating $X11_ROOT/output at $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir -p $X11_ROOT/output
  echo -e " done"
}

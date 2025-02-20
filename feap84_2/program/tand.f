c$Id:$
      function tand(x)

c      * * F E A P * * A Finite Element Analysis Program

c....  Copyright (c) 1984-2014: Regents of the University of California
c                               All rights reserved

c-----[--.----+----.----+----.-----------------------------------------]
c     Modification log                                Date (dd/mm/year)
c       Original version                                    01/11/2006
c       1. Use 'pi' from pconstant.h                        09/01/2008
c-----[--.----+----.----+----.-----------------------------------------]
c      Purpose: Compute tangent for degrees 'x'
c-----[--.----+----.----+----.-----------------------------------------]
      implicit none

      include 'pconstant.h'

      real*8 tand, x

      tand = tan(pi*x/180.d0)

      end

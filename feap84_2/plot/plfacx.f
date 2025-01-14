c$Id:$
      subroutine plfacx(ix,ia,ixf,nen,numel,ie,nie)

c      * * F E A P * * A Finite Element Analysis Program

c....  Copyright (c) 1984-2014: Regents of the University of California
c                               All rights reserved

c-----[--.----+----.----+----.-----------------------------------------]
c     Modification log                                Date (dd/mm/year)
c       Original version                                    01/11/2006
c       1. Do not perform sort if only one face             07/03/2007
c       2. In sort, change 'j-1' to 'j1' in 'm' loop        11/09/2007
c       3. Add option for quadratic order tets              24/10/2007
c          N.B. Still plotted as 3-node sub-triangles
c       4. Add option for pstyp < 0 for user face sets      31/08/2008
c       5. Add option for 64-node brick faces               07/02/2009
c       6. Separate surface pstyp to avoid conflict in nos. 01/09/2010
c       7. Add 'nel' on call to ufacelib                    08/12/2011
c       8. Change check on faces from different elements    10/06/2013
c-----[--.----+----.----+----.-----------------------------------------]
c      Purpose: Construct surface mesh array - ixf

c      Inputs:
c         ix(nen1,*)- Element nodal connection lists
c         ia(*)     - Active element plots based on materials
c         nen       - Dimension of ix array
c         numel     - Number of elements
c         ie(nie,*) - Assembly data for material sets
c         nie       - Dimension of ie array

c      Outputs:
c         ixf(7,*)  - Face array
c-----[--.----+----.----+----.-----------------------------------------]
      implicit  none

      include  'pbody.h'
      include  'pdata5.h'
      include  'pdata6.h'
      include  'sdata.h'

      include  'pointer.h'
      include  'comblk.h'

      logical   lclip,addfac, setval,palloc
      integer   nen,numel,nie, i,j,j1,m,n, nf, iel,iiel,ien,nel,pstyp
      integer   ufac
      integer   ix(nen1,numel), ia(*), ixf(7,*), ie(nie,*)
      integer   iq(4,7), it(3,4), it2(3,16), iline(6), ii(4)

      save

c     8-node brick faces

      data iq/3,2,1,4, 1,2,6,5, 2,3,7,6, 3,4,8,7, 4,1,5,8, 5,6,7,8,
     &        1,2,3,4/

c     4-node tet faces

      data it/1,2,4, 2,3,4, 3,1,4, 1,3,2/

c     10-node tet faces

      data it2 / 1, 5, 8,  5, 2, 9,  5, 9, 8,  8, 9, 4,
     &           2, 6, 9,  6, 3,10,  6,10, 9,  9,10, 4,
     &           3, 7,10,  7, 1, 8,  7, 8,10, 10, 8, 4,
     &           1, 7, 5,  7, 3, 6,  7, 6, 5,  5, 6, 2 /

c     Compute location of boundary faces

      nf = 1
      do n = 1,numel
        if(ix(nen1-1,n).ge.nreg1 .and. ix(nen1-1,n).le.nreg2 .and.
     &     ix(nen1-1,n).ge.0 .and. ia(n).ge.0) then
          pstyp = ie(1,ix(nen1,n))
          if(pstyp.gt.0) then
            iel = ie(nie-1,ix(nen1,n))
            do j = nen,1,-1
              if(ix(j,n).gt.0) then
                nel = j
                exit
              endif
            end do ! j

c           Get plot type

            call plftyp(pstyp,nel,iel)

            if(iel.gt.0) then
              iiel = inord(iel)
            else
              iiel = exord(-iel)
            endif

c           6-node triangle

            if(iiel.eq.7) then
              ien = 3
            else
              ien = nen
            endif

c           No face if inord < 0

            if     (iiel.lt.0) then

c           1-d elements

            elseif(pstyp .eq. 1) then

c             Set space for line elements

              if( iiel.gt.0 .and. iiel.le.3 ) then

c               Do a line element

                if( lclip(ix(1,n),2,hr(npxx),ndm) ) then
                  iline(1) = ix(1,n)
                  iline(2) = ix(2,n)
                  iline(3) = ix(2,n)
                  iline(4) = ix(1,n)
                  iline(5) = ix(nen1-1,n)
                  iline(6) = ix(nen1,n)

                  call pfacex(iq(1,7),iline,ixf(1,nf),4,6,nf,n)
                endif

              endif ! iiel > 0

c           2-d elements

            elseif(pstyp .eq. 2) then

c             Set space for top and bottom surface faces

              if( lclip(ix(1,n),min(4,ien),hr(npxx),ndm) ) then

c               Do a 2-d surface with both faces considered

                ii(1)  = 1
                do i = 2,min(4,ien)
                  if(ix(iq(i,1),n).gt.0) then
                    if(ix(iq(ii(1),1),n).gt.ix(iq(i,1),n)) then
                      ii(1)= i
                    endif
                  endif
                end do ! i
                ii(2) = mod(ii(1),min(4,ien)) + 1
                ii(3) = mod(ii(2),min(4,ien)) + 1
                ii(4) = mod(ii(3),min(4,ien)) + 1
                iline(4) = 0
                do j = 1,min(4,ien)
                  iline(j) = ix(iq(ii(j),1),n)
                end do ! j
                iline(5) = ix(nen1-1,n)
                iline(6) = ix(nen1,n)

                call pfacex(iq(1,7),iline,ixf(1,nf),min(ien,4),6,nf,-n)

                ii(1)  = 1
                do i = 2,min(4,ien)
                  if(ix(iq(i,7),n).gt.0) then
                    if(ix(iq(ii(1),7),n).gt.ix(iq(i,7),n)) then
                      ii(1)= i
                    endif
                  endif
                end do ! i
                ii(2) = mod(ii(1),min(4,ien)) + 1
                ii(3) = mod(ii(2),min(4,ien)) + 1
                ii(4) = mod(ii(3),min(4,ien)) + 1
                do j = 1,min(4,ien)
                  iline(j) = ix(iq(ii(j),7),n)
                end do ! j
                iline(5) = ix(nen1-1,n)
                iline(6) = ix(nen1,n)

                call pfacex(iq(1,7),iline,ixf(1,nf),min(ien,4),6,nf,-n)

              end if

c           3-d elements

            elseif (pstyp .eq. 3) then

c             Set for linear tetrahedral element faces

              if (iiel .eq. 9) then

                if( lclip(ix(1,n),4,hr(npxx),ndm) ) then
                  do m = 1,4
                    addfac = .true.
                    do j = 1,3
                      i = ix(it(j,m),n) - 1
                      if(mr(nprn+i).eq.0) then
                        addfac = .false.
                      endif
                    end do ! j

c                   Face is to be plotted if visible

                    if(addfac) then
                      ii(1)  = 1
                      do i = 2,3
                        if(ix(it(ii(1),m),n).gt.ix(it(i,m),n)) then
                          ii(1)= i
                        endif
                      end do ! i
                      ii(2) = mod(ii(1),3) + 1
                      ii(3) = mod(ii(2),3) + 1
                      iline(1) = ix(it(ii(1),m),n)
                      iline(2) = ix(it(ii(2),m),n)
                      iline(3) = ix(it(ii(3),m),n)
                      iline(4) = 0
                      iline(5) = ix(nen1-1,n)
                      iline(6) = ix(nen1,n)

                      call pfacex(iq(1,7),iline,ixf(1,nf),4,6,nf,n)

                    endif
                  end do ! m
                end if

c             Set for quadratic tetrahedral element faces

              elseif (iiel .eq. 15) then

                if( lclip(ix(1,n),10,hr(npxx),ndm) ) then
                  do m = 1,16
                    addfac = .true.
                    do j = 1,3
                      i = ix(it2(j,m),n) - 1
                      if(mr(nprn+i).eq.0) then
                        addfac = .false.
                      endif
                    end do ! j

c                   Face is to be plotted if visible

                    if(addfac) then
                      ii(1)  = 1
                      do i = 2,3
                        if(ix(it2(ii(1),m),n).gt.ix(it2(i,m),n)) then
                          ii(1)= i
                        endif
                      end do ! i
                      ii(2) = mod(ii(1),3) + 1
                      ii(3) = mod(ii(2),3) + 1
                      iline(1) = ix(it2(ii(1),m),n)
                      iline(2) = ix(it2(ii(2),m),n)
                      iline(3) = ix(it2(ii(3),m),n)
                      iline(4) = 0
                      iline(5) = ix(nen1-1,n)
                      iline(6) = ix(nen1,n)

                      call pfacex(iq(1,7),iline,ixf(1,nf),4,6,nf,n)

                    endif
                  end do ! m
                end if

c             Set for 64-node brick element faces

              elseif (iiel .eq. 46 ) then

                if( lclip(ix(1,n),nen,hr(npxx),ndm) ) then
                  call pfacepqr( 3,ipu,ufac)
                  do m = 1,ufac
                    addfac = .true.
                    do j = 1,4
                      i = ix(ipu(j,m),n) - 1
                      if(mr(nprn+i).eq.0) then
                        addfac = .false.
                      endif
                    end do ! j

c                   Face is to be plotted if visible

                    if(addfac) then
                      do j = 1,4
                        iline(j) = ix(ipu(j,m),n)
                      end do ! j
                      iline(5) = ix(nen1-1,n)
                      iline(6) = ix(nen1,n)

                      call pfacex(iq(1,7),iline,ixf(1,nf),4,6,nf,n)

                    endif
                  end do ! m
                end if

c             Set for brick element faces

              elseif (iiel .gt. 10 ) then

                if( lclip(ix(1,n),8,hr(npxx),ndm) ) then
                  do m = 1,6
                    addfac = .true.
                    do j = 1,4
                      i = ix(iq(j,m),n) - 1
                      if(mr(nprn+i).eq.0) then
                        addfac = .false.
                      endif
                    end do ! j

c                   Face is to be plotted if visible

                    if(addfac) then
                      ii(1)  = 1
                      do i = 2,4
                        if(ix(iq(ii(1),m),n).gt.ix(iq(i,m),n)) then
                          ii(1)= i
                        endif
                      end do ! i
                      ii(2) = mod(ii(1),4) + 1
                      ii(3) = mod(ii(2),4) + 1
                      ii(4) = mod(ii(3),4) + 1
                      do j = 1,4
                        iline(j) = ix(iq(ii(j),m),n)
                      end do ! j
                      iline(5) = ix(nen1-1,n)
                      iline(6) = ix(nen1,n)

                      call pfacex(iq(1,7),iline,ixf(1,nf),4,6,nf,n)

                    endif
                  end do ! m
                end if

              endif ! iiel

            endif ! pstyp > 0

c         User element test

          elseif(pstyp.lt.0) then

            if( lclip(ix(1,n),nen,hr(npxx),ndm) ) then
              call ufacelib(pstyp,nel,ipu,ufac)
              do m = 1,ufac
                addfac = .true.
                do j = 1,4
                  i = ix(ipu(j,m),n) - 1
                  if(mr(nprn+i).eq.0) then
                    addfac = .false.
                  endif
                end do ! j

c               Face is to be plotted if visible

                if(addfac) then
                  do j = 1,4
                    iline(j) = ix(ipu(j,m),n)
                  end do ! j
                  iline(5) = ix(nen1-1,n)
                  iline(6) = ix(nen1,n)

                  call pfacex(iq(1,7),iline,ixf(1,nf),4,6,nf,n)

                endif
              end do ! m
            end if

          end if ! pstyp
        end if
      end do ! n

c     Sort faces

      nf = nf - 1
      if(nf.gt.1) then
        setval = palloc(112,'TEMP2',7*nf,1)
        call mergei( 0, 7, ixf, nf, mr(np(112)) )
        setval = palloc(112,'TEMP2', 0,1)
      endif

c     Search for matching faces and delete

      i  = 1
      ii(1) = ixf(1,i)
      do j = 2,nf
        if(ixf(1,j).gt.ii(1) .or. j.eq.nf) then
          if(j.eq.nf) then
            j1 = nf
          else
            j1 = j - 1
          endif
          do m = i,j1
            if( ixf(4,m).eq.0 .or. ixf(4,m).eq.ixf(1,m)) then
              do n = m+1,j1
                if(ixf(2,m).eq.ixf(3,n) .and.
     &             ixf(3,m).eq.ixf(2,n) .and.
     &            (ixf(4,n).eq.ixf(1,n) .or. ixf(4,n).eq.0) .and.
     &             ixf(5,m).gt.0      ) then
c    &            (ixf(5,m).eq.ixf(5,n) .and.ixf(5,n).gt.0)) then
                  ixf(7,m) = - abs(ixf(7,m))
                  ixf(7,n) = - abs(ixf(7,n))
                endif
              end do ! n
              ixf(4,m) = ixf(1,m)
            else
              do n = m+1,j1
                if(ixf(2,m).eq.ixf(4,n) .and.
     &             ixf(4,m).eq.ixf(2,n) .and.
     &             ixf(3,m).eq.ixf(3,n) .and.
     &             ixf(5,m).gt.0      ) then
c    &            (ixf(5,m).eq.ixf(5,n) .and.ixf(5,n).gt.0)) then
                  ixf(7,m) = - abs(ixf(7,m))
                  ixf(7,n) = - abs(ixf(7,n))
                endif
              end do ! n
            endif
          end do ! m
          i  = j
          ii(1) = ixf(1,j)
        endif
      end do ! j

      end

c$Id:$
      subroutine srvemat(d,eps,ta,hn,hn1,nh, sig,dd,isw)

c      * * F E A P * * A Finite Element Analysis Program

c....  Copyright (c) 1984-2014: Regents of the University of California
c                               All rights reserved

c-----[--.----+----.----+----.-----------------------------------------]
c     Modification log                                Date (dd/mm/year)
c       Original version                                    10/12/2007
c       1. Add allocation of 'RVEMA' and set to ma          13/04/2009
c       2. Add temperature to sends (was umatl2)            13/06/2009
c       3. Set size of send/receive arrays                  07/02/2010
c       4. Define and use 'hpar', pass detf = 1.0           03/12/2010
c       5. Add 'd' to argument and store density            10/05/2012
c       6. Replace 'omacr1.h' by 'elpers.h'                 21/05/2013
c-----[--.----+----.----+----.-----------------------------------------]
c     Purpose: User Constitutive Model for MPI2 Exchanges

c     Input:
c          eps(6)  -  Strain at point (small deformation)
c          ta      -  Temperature change
c          hn(nh)  -  History terms at point: t_n
c          nh      -  Number of history terms
c          isw     -  Solution option from element

c     Output:
c          hn1(nh) -  History terms at point: t_n+1
c          sig(*)  -  Stresses at point.
c                     N.B. 1-d models use only sig(1)
c          dd(6,*) -  Current material tangent moduli
c                     N.B. 1-d models use only dd(1,1) and dd(2,1)
c-----[--.----+----.----+----.-----------------------------------------]
      implicit   none

      include   'cdata.h'
      include   'counts.h'
      include   'debugs.h'
      include   'eldata.h'
      include   'elpers.h'
      include   'hdatam.h'
      include   'iofile.h'
      include   'sdata.h'
      include   'setups.h'
      include   'tdata.h'

      include   'mpif.h'

      include   'pointer.h'
      include   'comblk.h'

      logical    setval,palloc
      integer    nh,isw
      integer    a,b
      real*8     ta, hpar
      real*8     d(*),eps(6),hn(nh), hn1(nh), sig(*),dd(6,*)

c     Compute and output stress (sig) and (moduli)

      save

      if(debug) then
        call udebug('   srvemat',isw)
      endif

c     Set values of isw to send information to micro-scale problem

      if(isw.eq.14) then

c       Store material number for each send

        setval = palloc(269,'RVEMA',nsend+1, 1)
        mr(np(269)+nsend) = ma

c       Count number of sends

        sendfl = .true.
        nsend  = nsend + 1

c       Set send receive sizes

        dsend = max(dsend,13)
        drecv = max(drecv,45)

      elseif(isw.eq.4 .or. isw.eq.8) then

        do a = 1,6
          sig(a) = hn1(a)
        end do ! a

      elseif(isw.eq.3 .or. isw.eq.6 .or. isw.eq.12) then

c       Use current value of stress from array

        if(pltmfl) then

          do a = 1,6
            sig(a) = hn1(a)
          end do ! a

c       Move deformation gradient to send buffer

        elseif(sendfl) then

          if(nh.gt.6) then
            hpar = hn(7)
          else
            hpar = 0.0d0
          endif
          call usstore(hr(np(260)),hpar, n, dsend,nrecv, eps, ta)

          if(debug) then
            call mprint(eps,1,6,1,'eps_send_4')
          endif

c         This is a set to prevent adding non-zeros to tangent/residual

          do a = 1,6
            sig(a) = 0.0d0
            do b = 1,6
              dd(b,a) = 0.0d0
            end do ! b
          end do ! a

c       Put Cauchy stress and moduli in arrays

        elseif(recvfl) then

          call usrecv(d,hr(np(261)), drecv,nrecv, sig,dd)

c         Save stress for outputs

          if(hflgu) then
            do a = 1,6
              hn1(a) = sig(a)
            end do ! a
          endif

          if(debug) then
            call mprint(sig,1,6,1,'SIG_recv_4')
            call mprint(dd,6,6,6,'D_recv_4')
          endif

        endif ! Receive

      endif

      end

      subroutine usstore(frvel, hpar,n, dsend,nsend, eps, ta)

      implicit   none

      include   'iofile.h'

      integer    i, n,dsend,nsend
      real*8     hpar
      real*8     ta, frvel(dsend,*), eps(6)

      save

      nsend          = nsend + 1
      frvel(1,nsend) = n
      frvel(2,nsend) = hpar
      do i = 1,6
        frvel(i+2,nsend) = eps(i)
      end do ! i
      frvel(12,nsend) = 1.0d0
      frvel(13,nsend) = ta

      end

      subroutine usrecv(d,srvel, drecv,nsend, tau,ctau)

      implicit   none

      include   'debugs.h'
      include   'eldata.h'

      integer    drecv,nsend,a,b,k
      real*8     d(*),srvel(drecv,*), tau(*),ctau(6,6)

      save

      nsend = nsend + 1
      do a = 1,6
        tau(a) = srvel(a+1,nsend)
      end do ! i
      k = 7
      do a = 1,6
        do b = 1,6
          k = k + 1
          ctau(b,a) = srvel(k,nsend)
        end do ! b
      end do ! a

c     Set density

      d(4) = srvel(44,nsend)

      if(debug) then
        call mprint( tau,1,6,1,'SIG_rve')
        call mprint(ctau,6,6,6,'DD_rve')
      endif

      end
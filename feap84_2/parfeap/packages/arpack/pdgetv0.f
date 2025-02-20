c$Id:$

c      * * F E A P * * A Finite Element Analysis Program

c....  Copyright (c) 1984-2014: Regents of the University of California
c                               All rights reserved

c-----[--.----+----.----+----.-----------------------------------------]
c     Modification log                                Date (dd/mm/year)
c       Original version                                    01/11/2006
c       1. Remove itry from argument (unused)               11/04/2013
c       2. Add dum(1) for passing rnorm and rnorm0          06/01/2014
c-----------------------------------------------------------------------
c\BeginDoc

c  This source file has been adapted from the arpack distribution and is
c  distributed with feap under the following license conditions

c  Rice BSD Software License

c  Permits source and binary redistribution of the software
c  ARPACK and P_ARPACK  for both non-commercial and commercial use.

c  Copyright (c) 2001, Rice University
c  Developed by D.C. Sorensen, R.B. Lehoucq, C. Yang, and K. Maschhoff.
c  All rights reserved.

c  Redistribution and use in source and binary forms, with or without
c  modification, are permitted provided that the following conditions are met:

c  _ Redistributions of source code must retain the above copyright notice,
c    this list of conditions and the following disclaimer.
c  _ Redistributions in binary form must reproduce the above copyright notice,
c    this list of conditions and the following disclaimer in the documentation
c    and/or other materials provided with the distribution.
c  _ If you modify the source for these routines we ask that you change the
c    name of the routine and comment the changes made to the original.
c  _ Written notification is provided to the developers of  intent to use this
c    software.

c  Also, we ask that use of ARPACK is properly cited in any resulting
c  publications or software documentation.

c  _ Neither the name of Rice University (RICE) nor the names of its
c    contributors may be used to endorse or promote products derived from
c    this software without specific prior written permission.

c  THIS SOFTWARE IS PROVIDED BY RICE AND CONTRIBUTORS "AS IS" AND
c  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
c  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
c  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL RICE OR
c  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
c  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
c  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
c  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
c  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
c  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
c  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
c  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


c\Name: pdgetv0

c\Description:
c  Generate a random initial residual vector for the Arnoldi process.
c  Force the residual vector to be in the range of the operator OP.

c\Usage:
c  call pdgetv0
c     ( IDO, BMAT, ITRY, INITV, N, J, V, LDV, RESID, RNORM,
c       IPNTR, WORKD, IERR )

c\Arguments
c  IDO     Integer.  (INPUT/OUTPUT)
c          Reverse communication flag.  IDO must be zero on the first
c          call to pdgetv0.
c          -------------------------------------------------------------
c          IDO =  0: first call to the reverse communication interface
c          IDO = -1: compute  Y = OP * X  where
c                    IPNTR(1) is the pointer into WORKD for X,
c                    IPNTR(2) is the pointer into WORKD for Y.
c                    This is for the initialization phase to force the
c                    starting vector into the range of OP.
c          IDO =  2: compute  Y = B * X  where
c                    IPNTR(1) is the pointer into WORKD for X,
c                    IPNTR(2) is the pointer into WORKD for Y.
c          IDO = 99: done
c          -------------------------------------------------------------

c  BMAT    Character*1.  (INPUT)
c          BMAT specifies the type of the matrix B in the (generalized)
c          eigenvalue problem A*x = lambda*B*x.
c          B = 'I' -> standard eigenvalue problem A*x = lambda*x
c          B = 'G' -> generalized eigenvalue problem A*x = lambda*B*x

c  ITRY    Integer.  (INPUT)
c          ITRY counts the number of times that pdgetv0 is called.
c          It should be set to 1 on the initial call to dgetv0.

c  INITV   Logical variable.  (INPUT)
c          .TRUE.  => the initial residual vector is given in RESID.
c          .FALSE. => generate a random initial residual vector.

c  N       Integer.  (INPUT)
c          Dimension of the problem.

c  J       Integer.  (INPUT)
c          Index of the residual vector to be generated, with respect to
c          the Arnoldi process.  J > 1 in case of a "restart".

c  V       Double precision N by J array.  (INPUT)
c          The first J-1 columns of V contain the current Arnoldi basis
c          if this is a "restart".

c  LDV     Integer.  (INPUT)
c          Leading dimension of V exactly as declared in the calling
c          program.

c  RESID   Double precision array of length N.  (INPUT/OUTPUT)
c          Initial residual vector to be generated.  If RESID is
c          provided, force RESID into the range of the operator OP.

c  RNORM   Double precision scalar.  (OUTPUT)
c          B-norm of the generated residual.

c  IPNTR   Integer array of length 3.  (OUTPUT)

c  WORKD   Double precision work array of length 2*N.  (REVERSE COMMUNICATION).
c          On exit, WORK(1:N) = B*RESID to be used in SSAITR.

c  IERR    Integer.  (OUTPUT)
c          =  0: Normal exit.
c          = -1: Cannot generate a nontrivial restarted residual vector
c                in the range of the operator OP.

c\EndDoc

c-----------------------------------------------------------------------

c\BeginLib

c\Local variables:
c     xxxxxx  real

c\References:
c  1. D.C. Sorensen, "Implicit Application of Polynomial Filters in
c     a k-Step Arnoldi Method", SIAM J. Matr. Anal. Apps., 13 (1992),
c     pp 357-385.
c  2. R.B. Lehoucq, "Analysis and Implementation of an Implicitly
c     Restarted Arnoldi Iteration", Rice University Technical Report
c     TR95-13, Department of Computational and Applied Mathematics.

c\Routines called:
c     second  ARPACK utility routine for timing.
c     dvout   ARPACK utility routine for vector output.
c     dlarnv  LAPACK routine for generating a random vector.
c     dgemv   Level 2 BLAS routine for matrix vector multiplication.
c     dcopy   Level 1 BLAS that copies one vector to another.
c     ddot    Level 1 BLAS that computes the scalar product of two vectors.
c     dnrm2   Level 1 BLAS that computes the norm of a vector.

c\Author
c     Danny Sorensen               Phuong Vu
c     Richard Lehoucq              CRPC / Rice University
c     Dept. of Computational &     Houston, Texas
c     Applied Mathematics
c     Rice University
c     Houston, Texas

c\SCCS Information: @(#)
c FILE: getv0.F   SID: 2.7   DATE OF SID: 04/07/99   RELEASE: 2

c\EndLib

c-----------------------------------------------------------------------

      subroutine pdgetv0
     &   ( ido, bmat, initv, n, j, v, ldv, resid, rnorm,
     &     ipntr, workd, ierr )
      implicit   none

c     %----------------------------------------------------%
c     | Include files for debugging and timing information |
c     %----------------------------------------------------%

      include   'debug.h'
      include   'stat.h'

      include   'pfeapb.h'

c     %------------------%
c     | Scalar Arguments |
c     %------------------%

      character  bmat*1
      logical    initv
      integer    ido, ierr, j, ldv, n
      Double precision
     &           rnorm

c     %-----------------%
c     | Array Arguments |
c     %-----------------%

      integer    ipntr(3)
      Double precision
     &           resid(n), v(ldv,j), workd(2*n)

c     %------------%
c     | Parameters |
c     %------------%

      Double precision
     &           one         , zero
      parameter (one = 1.0D+0, zero = 0.0D+0)

c     %------------------------%
c     | Local Scalars & Arrays |
c     %------------------------%

      logical    first, inits, orth
      integer    idist, iseed(4), iter, msglvl, jj
      Double precision
     &           rnorm0, dum(1)
      Double precision
     &           tbuf(n*2)
      real*4     tary(2), etime, t0,t1,t2,t3

      save       first, iseed, inits, iter, msglvl, orth, rnorm0
      save       t0,t1,t2,t3

c     %----------------------%
c     | External Subroutines |
c     %----------------------%

c     external   dlarnv, dvout, dcopy, dgemv, second
      external   dlarnv, dvout, dcopy, dgemv

c     %--------------------%
c     | External Functions |
c     %--------------------%

      Double precision
     &           pddot, pdnrm2
      external   pddot, pdnrm2

c     %---------------------%
c     | Intrinsic Functions |
c     %---------------------%

      intrinsic    abs, sqrt

c     %-----------------%
c     | Data Statements |
c     %-----------------%

      data       inits /.true./

c     %-----------------------%
c     | Executable Statements |
c     %-----------------------%


c     %-----------------------------------%
c     | Initialize the seed of the LAPACK |
c     | random number generator           |
c     %-----------------------------------%

      if (inits) then
          iseed(1) = 1
          iseed(2) = 3
          iseed(3) = 5
          iseed(4) = 7
          inits    = .false.
      end if

      if (ido .eq.  0) then

c        %-------------------------------%
c        | Initialize timing statistics  |
c        | & message level for debugging |
c        %-------------------------------%

c        call second (t0)
         t0 = etime(tary)
         msglvl = mgetv0

         ierr   = 0
         iter   = 0
         first  = .FALSE.
         orth   = .FALSE.

c        %-----------------------------------------------------%
c        | Possibly generate a random starting vector in RESID |
c        | Use a LAPACK random number generator used by the    |
c        | matrix generation routines.                         |
c        |    idist = 1: uniform (0,1)  distribution;          |
c        |    idist = 2: uniform (-1,1) distribution;          |
c        |    idist = 3: normal  (0,1)  distribution;          |
c        %-----------------------------------------------------%

         if (.not.initv) then
            idist = 2
            call dlarnv (idist, iseed, n, resid)
         end if

c        %----------------------------------------------------------%
c        | Force the starting vector into the range of OP to handle |
c        | the generalized problem when B is possibly (singular).   |
c        %----------------------------------------------------------%

c        call second (t2)
         t2 = etime(tary)
         if (bmat .eq. 'G') then
            nopx     = nopx + 1
            ipntr(1) = 1
            ipntr(2) = n + 1
            call dcopy (n, resid, 1, workd, 1)
            ido      = -1
            go to 9000
         end if
      end if

c     %-----------------------------------------%
c     | Back from computing OP*(initial-vector) |
c     %-----------------------------------------%

      if (first) go to 20

c     %-----------------------------------------------%
c     | Back from computing B*(orthogonalized-vector) |
c     %-----------------------------------------------%

      if (orth)  go to 40

      if (bmat .eq. 'G') then
c        call second (t3)
         t3 = etime(tary)
         tmvopx = tmvopx + (t3 - t2)
      end if

c     %------------------------------------------------------%
c     | Starting vector is now in the range of OP; r = OP*r; |
c     | Compute B-norm of starting vector.                   |
c     %------------------------------------------------------%

c     call second (t2)
      t2 = etime(tary)
      first = .TRUE.
      if (bmat .eq. 'G') then
         nbx      = nbx + 1
         call dcopy (n, workd(n+1), 1, resid, 1)
         ipntr(1) = n + 1
         ipntr(2) = 1
         ido      = 2
         go to 9000
      else if (bmat .eq. 'I') then
         call dcopy (n, resid, 1, workd, 1)
      end if

   20 continue

      if (bmat .eq. 'G') then
c        call second (t3)
         t3 = etime(tary)
         tmvbx = tmvbx + (t3 - t2)
      end if

      first = .FALSE.
      if (bmat .eq. 'G') then
          rnorm0 = pddot (n, resid, 1, workd, 1)
          rnorm0 = sqrt(abs(rnorm0))
      else if (bmat .eq. 'I') then
           rnorm0 = pdnrm2(n, resid, 1)
      end if
      rnorm  = rnorm0

c     %---------------------------------------------%
c     | Exit if this is the very first Arnoldi step |
c     %---------------------------------------------%

      if (j .eq. 1) go to 50

c     %----------------------------------------------------------------
c     | Otherwise need to B-orthogonalize the starting vector against |
c     | the current Arnoldi basis using Gram-Schmidt with iter. ref.  |
c     | This is the case where an invariant subspace is encountered   |
c     | in the middle of the Arnoldi factorization.                   |
c     |                                                               |
c     |       s = V^{T}*B*r;   r = r - V*s;                           |
c     |                                                               |
c     | Stopping criteria used for iter. ref. is discussed in         |
c     | Parlett's book, page 107 and in Gragg & Reichel TOMS paper.   |
c     %---------------------------------------------------------------%

      orth = .TRUE.
   30 continue

      call dgemv ('T', n, j-1, one, v, ldv, workd, 1,
     &            zero, workd(n+1), 1)
      call pfeapsr(workd(n+1),tbuf,j-1,.true.)  ! communicate the vector
      call dgemv ('N', n, j-1, -one, v, ldv, workd(n+1), 1,
     &            one, resid, 1)

c     %----------------------------------------------------------%
c     | Compute the B-norm of the orthogonalized starting vector |
c     %----------------------------------------------------------%

c     call second (t2)
      t2 = etime(tary)
      if (bmat .eq. 'G') then
         nbx      = nbx + 1
         call dcopy (n, resid, 1, workd(n+1), 1)
         ipntr(1) = n + 1
         ipntr(2) = 1
         ido      = 2
         go to 9000
      else if (bmat .eq. 'I') then
         call dcopy (n, resid, 1, workd, 1)
      end if

   40 continue

      if (bmat .eq. 'G') then
c        call second (t3)
         t3 = etime(tary)
         tmvbx = tmvbx + (t3 - t2)
      end if

      if (bmat .eq. 'G') then
         rnorm = pddot (n, resid, 1, workd, 1)
         rnorm = sqrt(abs(rnorm))
      else if (bmat .eq. 'I') then
         rnorm = pdnrm2(n, resid, 1)
      end if

c     %--------------------------------------%
c     | Check for further orthogonalization. |
c     %--------------------------------------%

      if (msglvl .gt. 2) then
          dum(1) = rnorm0
          call dvout (logfil, 1, dum, ndigit,
     &                'pdgetv0: re-orthonalization ; rnorm0 is')
          dum(1) = rnorm
          call dvout (logfil, 1, dum, ndigit,
     &                'pdgetv0: re-orthonalization ; rnorm is')
      end if

      if (rnorm .gt. 0.717*rnorm0) go to 50

      iter = iter + 1
      if (iter .le. 5) then

c        %-----------------------------------%
c        | Perform iterative refinement step |
c        %-----------------------------------%

         rnorm0 = rnorm
         go to 30
      else

c        %------------------------------------%
c        | Iterative refinement step "failed" |
c        %------------------------------------%

         do jj = 1, n
            resid(jj) = zero
         end do ! jj
         rnorm = zero
         ierr  = -1
      end if

   50 continue

      if (msglvl .gt. 0) then
         dum(1) = rnorm
         call dvout (logfil, 1, dum, ndigit,
     &        'pdgetv0: B-norm of initial / restarted starting vector')
      end if
      if (msglvl .gt. 3) then
         call dvout (logfil, n, resid, ndigit,
     &        'pdgetv0: initial / restarted starting vector')
      end if
      ido = 99

c     call second (t1)
      t1 = etime(tary)
      tgetv0 = tgetv0 + (t1 - t0)

 9000 continue

c     %---------------%
c     | End of dgetv0 |
c     %---------------%

      end

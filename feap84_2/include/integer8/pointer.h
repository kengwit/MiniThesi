
      integer          num_nps       , num_ups
      parameter       (num_nps = 400 , num_ups = 200)

      integer*8        np         , up                          ! int8
      common /pointer/ np(num_nps), up(num_ups)

      integer*8        npid,npix,npuu,npxx,nper,npnp,npev,nprn,npty
      common /npoints/ npid,npix,npuu,npxx,nper,npnp,npev,nprn,npty

      integer*8        npud
      common /npoints/ npud

      integer*8        plix
      common /ppoints/ plix

!     integer*8        np31,np33,np40,np43,np57,np58,np77,np89,np190
!     common /npoints/ np31,np33,np40,np43,np57,np58,np77,np89,np190

!     integer*8        np42
!     common /npoints/ np42

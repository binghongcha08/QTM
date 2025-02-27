      SUBROUTINE bsstep(y,dydx,nv,x,htry,eps,yscal,hdid,hnext,derivs)
C--------------------------------------------------------------------
C    DOUBLE PRECISION VERSION
C--------------------------------------------------------------------
      INTEGER nv,NMAX,KMAXX,IMAX
      REAL*8 eps,hdid,hnext,htry,x,dydx(nv),y(nv),yscal(nv),SAFE1,SAFE2,
     *REDMAX,REDMIN,TINY,SCALMX
      PARAMETER (NMAX=50,KMAXX=8,IMAX=KMAXX+1,SAFE1=.25,SAFE2=.7,
     *REDMAX=1.e-5,REDMIN=.7,TINY=1.e-30,SCALMX=.1)
CU    USES derivs,mmid,pzextr
      INTEGER i,iq,k,kk,km,kmax,kopt,nseq(IMAX)
      REAL*8 eps1,epsold,errmax,fact,h,red,scale,work,wrkmin,xest,xnew,
     *a(IMAX),alf(KMAXX,KMAXX),err(KMAXX),yerr(NMAX),ysav(NMAX),
     *yseq(NMAX)
      LOGICAL first,reduct
      SAVE a,alf,epsold,first,kmax,kopt,nseq,xnew
      EXTERNAL derivs
      DATA first/.true./,epsold/-1./
      DATA nseq /2,4,6,8,10,12,14,16,18/
C
      if(eps.ne.epsold)then
        hnext=-1.e29
        xnew=-1.e29
        eps1=SAFE1*eps
        a(1)=nseq(1)+1
        do 11 k=1,KMAXX
          a(k+1)=a(k)+nseq(k+1)
11      continue
        do 13 iq=2,KMAXX
          do 12 k=1,iq-1
            alf(k,iq)=eps1**((a(k+1)-a(iq+1))/((a(iq+1)-a(1)+1.)*(2*k+
     *1)))
12        continue
13      continue
        epsold=eps
        do 14 kopt=2,KMAXX-1
          if(a(kopt+1).gt.a(kopt)*alf(kopt-1,kopt))goto 1
14      continue
1       kmax=kopt
      endif
      h=htry
      do 15 i=1,nv
        ysav(i)=y(i)
15    continue
      if(h.ne.hnext.or.x.ne.xnew)then
        first=.true.
        kopt=kmax
      endif
      reduct=.false.
2     do 17 k=1,kmax
        xnew=x+h
        if(xnew.eq.x)pause 'step size underflow in bsstep'
        call mmid(ysav,dydx,nv,x,h,nseq(k),yseq,derivs)
        xest=(h/nseq(k))**2
        call pzextr(k,xest,yseq,y,yerr,nv)
        if(k.ne.1)then
          errmax=TINY
          do 16 i=1,nv
            errmax=max(errmax,abs(yerr(i)/yscal(i)))
16        continue
          errmax=errmax/eps
          km=k-1
          err(km)=(errmax/SAFE1)**(1./(2*km+1))
        endif
        if(k.ne.1.and.(k.ge.kopt-1.or.first))then
          if(errmax.lt.1.)goto 4
          if(k.eq.kmax.or.k.eq.kopt+1)then
            red=SAFE2/err(km)
            goto 3
          else if(k.eq.kopt)then
            if(alf(kopt-1,kopt).lt.err(km))then
              red=1./err(km)
              goto 3
            endif
          else if(kopt.eq.kmax)then
            if(alf(km,kmax-1).lt.err(km))then
              red=alf(km,kmax-1)*SAFE2/err(km)
              goto 3
            endif
          else if(alf(km,kopt).lt.err(km))then
            red=alf(km,kopt-1)/err(km)
            goto 3
          endif
        endif
17    continue
3     red=min(red,REDMIN)
      red=max(red,REDMAX)
      h=h*red
      reduct=.true.
      goto 2
4     x=xnew
      hdid=h
      first=.false.
      wrkmin=1.e35
      do 18 kk=1,km
        fact=max(err(kk),SCALMX)
        work=fact*a(kk+1)
        if(work.lt.wrkmin)then
          scale=fact
          wrkmin=work
          kopt=kk+1
        endif
18    continue
      hnext=h/scale
      if(kopt.ge.k.and.kopt.ne.kmax.and..not.reduct)then
        fact=max(scale/alf(kopt-1,kopt),SCALMX)
        if(a(kopt+1)*fact.le.wrkmin)then
          hnext=h/fact
          kopt=kopt+1
        endif
      endif
      return
      END

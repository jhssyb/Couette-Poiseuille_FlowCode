module module_solver

implicit none

contains
!====================================================================
!>Subroutine to calculate velocity profile
!====================================================================
SUBROUTINE SOLVE_CP(U,ERROR,U1,VW,H,N,LD,MD,UD,D,YPAD,YHAD,ALPHA,DPDX,DYN_VIS,KIN_VIS,RHO,CONV_CRIT,OUTPUTFILE)
	IMPLICIT NONE
	INTEGER :: I,J,K,COUNTER
	INTEGER,INTENT(IN):: N
	REAL(8),INTENT(IN):: YPAD(N),H,VW,YHAD(N),ALPHA,DPDX,CONV_CRIT
	REAL(8),INTENT(IN):: DYN_VIS,KIN_VIS,RHO
	REAL(8),INTENT(INOUT):: U(N)
	REAL(8)			  ::ERROR,U1(N),LD(1:N),MD(1:N),UD(1:N),D(1:N),LEN_ZERO(N),UTAU1,UTAU2,A1,A2,MIX_LEN(N)
	REAL(8)			  ::TKIN_VISN(1:N),TKIN_VISS(1:N),A(1:N),B(1:N),U_AVG,YF(N-1)
	CHARACTER(len=15),INTENT(IN):: OUTPUTFILE
	open(33,file=OUTPUTFILE)	
	
	ERROR=1.0D0
	U1=0.0d0
	YF(1)=0.0D0
	DO I=2,N-1
		YF(I)=YPAD(I)+ (YPAD(I)-YF(I-1)) !YPAD at the faces of the control volume
	END DO
	DO I= 2,N-1	
		LEN_ZERO(I)=(0.21D0-(0.43D0*((1.0D0-(2.0D0*(YF(I)/H)))**4)) + (0.22D0*((1.0D0-(2.0D0*(YF(I))/H))**6)))*(H/2.0D0)
	END DO
	
	COUNTER=0 !total iterations for convergence
	Do 
		
		IF(ERROR>CONV_CRIT)THEN !convergence criteria
		U1=0.0d0			
							
		UTAU1=DSQRT((dabs(U(2))/(YPAD(2)))*KIN_VIS)		
		
		UTAU2=DSQRT((dabs(U(N-1)-U(N))/(YHAD(N)))*KIN_VIS) 
                A1=26.0d0*KIN_VIS/UTAU1 			!FOR LOWER WALL
		
		A2=26.0d0*KIN_VIS/UTAU2				!FOR UPPER WALL
	
		Do I=2,(N+1)/2	
		
			MIX_LEN(I)=LEN_ZERO(I)*(1.0d0-DEXP(-YF(I)/A1))
		
			MIX_LEN(N-(I-1))=LEN_ZERO(N-(I-1))*(1.0d0-DEXP(-YF(I)/A2))	

		END DO
		DO I=2,N-1		
			TKIN_VISN(I)=(MIX_LEN(I)**2)*Dabs((U(I+1)-U(I))/(YHAD(I+1))) ! Turbulent viscosity
			!print*,"TKIN_VISN=",TKIN_VISN(I)
			
		END DO
		DO I=2,N-1
			A(I)= KIN_VIS + TKIN_VISN(I)   
			
			B(I)= KIN_VIS + TKIN_VISN(I-1)  	
		
		END DO
		!Initialise thomas matrix
		LD=0.0d0;MD=0.0d0;UD=0.0d0
		
		DO I=2,N-1
			LD(I)=B(I)/YHAD(I)							!LD= lower diagonal 
			MD(I)=-((A(I)/YHAD(I+1))+(B(I)/YHAD(I)))	!MD= middle diagonal 
			UD(I)=A(I)/(YHAD(I+1))						!UP= Upper diagonal
		END DO
		!Boundary Conditions
		MD(1)=1.0D0;MD(N)=1.0D0	
		UD(1)=1.0D0;LD(N)=1.0D0;LD(1)=0.0D0;UD(N)=0.0D0 
		D(1)=0.0d0
		DO I=2,N-1
			D(I)=DPDX*((YPAD(I+1)-YPAD(I-1))/2.0d0)
		END DO
		D(N)=2.0D0*VW
		!Forward Ellimination	
		do I=2,N
			MD(I)=MD(I)-((LD(I)/MD(I-1))*UD(I-1))
			D(I)=D(I)-((LD(I)/MD(I-1))*D(I-1))
		end do
		!Back substitution
		U1(N)=D(N)/MD(N) !back substitution
		do I=N-1,1,-1
			U1(I)=(D(I)-(UD(I)*U1(I+1)))/MD(I) !Numerical values calculated using thomas algoritham
		end do

		ERROR=0.0d0
		DO I=2,N-1
  			ERROR=ERROR+(U(I)-U1(I))**2
  		END DO
		ERROR=DSQRT(ERROR/DFLOAT(N-2))
		!print*,"Error=",ERROR
		U=U1
		COUNTER= COUNTER+1
		
		ELSEIF(ERROR<CONV_CRIT)THEN
  		EXIT
  		ENDIF
  	END DO
	print*,"Number of iterations=",COUNTER
	UTAU1=SQRT((abs(U(2))/(YPAD(2)))*KIN_VIS)
	PRINT*,"UTAU1=",UTAU1		
	UTAU2=SQRT((abs(U(N-1)-U(N))/(YHAD(N)))*KIN_VIS)
	PRINT*,"UTAU2=",UTAU2
	U_AVG=SUM(U(2:N-1))/DFLOAT(N-2)
	print*,"U_AVG=",ABS(U_AVG),"U_Max=",MAXVAL(ABS(U))
	!WRITE(77,"(ES16.8,I8,I10,5ES16.8)")ALPHA,N,COUNTER,VW,MAXVAL(ABS(U)),ABS(U_AVG),UTAU1,UTAU2
	print*, ALPHA,N,COUNTER,VW,MAXVAL(ABS(U)),ABS(U_AVG),UTAU1,UTAU2
	WRITE(33,"(2ES16.8)")0.0D0,0.0D0 
	DO I=2,N-1
		WRITE(33,"(2ES16.8)")YPAD(I)/H,U(I)/VW			
		
	END DO
	WRITE(33,"(2ES16.8)")1.0D0,1.0d0 
	CLOSE(33)
END SUBROUTINE



end module module_solver

function [momin,ppd1d,ppd2d]=plot_gridsearch(models,energy,bounds,gibbsopt,inverseopt,objfuncopt,momin,ppd1d,ppd2d)
% 
% PLOT_GIBBS   plots 1-D and 2-D marginal probability distributions
%
% usage:  [momin,ppd1d,ppd2d]=plot_gibbs(models,energy,bounds,gibbsopt,momin,ppd1d,ppd2d)
%
%    PLOT_GIBBS(MODELS,ENERGY,BOUNDS,OPT)                       calculates ppds and mean
%    PLOT_GIBBS(MODELS,ENERGY,BOUNDS,OPT,MMEAN,PPD1D,PPD2D)     uses the given values
%    PLOT_GIBBS(MODELS1,MODELS2,BOUNDS,OPT,BINS)     uses the given values
%  

% FA Feb 2008

%Check argument syntax

if nargin<4
	error('Usage: []=plot_gridsearch(models,energy,bounds,gibbsopt,ppd1d,ppd2d)')
end

if isempty(gridsearchopt)
       igrid=4;
       matrix=0;
else
      f=fieldnames(gridsearchopt) ; for i=1:length(f) eval([char(f{i}) '= gridsearchopt.(f{i}) ;' ]) ; end
	   if plot_bins
	      bingrid=gibbsopt.plot_bins;
       else
	      bingrid=2*2^igrid
       end
end

  delta=bounds(:,2)-bounds(:,1);

mdim=size(models,1);
mpl=ceil(sqrt(mdim)); npl=ceil(mdim/mpl);

modelgrid=zeros(mdim,bingrid);
val=[0:1/bingrid:1]; val=val(2:end)-1/bingrid/2; 
modelgrid=bounds(:,1)*ones(1,bingrid)+delta*val;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if ~exist('ppd2d') [momin,ppd1d,ppd2d]=calc_ppd(models,energy,modelgrid); end
   maxppd=mmax(ppd1d); set(gcf,'DefaultAxesYlim',[0 maxppd])
   [h,ax,BigAx,P,Pax]=plotmatrix([zeros(mdim,mdim)]) ;
   
   % remove unecessary axes
   for i=1:mdim-1
       delete(ax(i,i+1:mdim))
   end
   hold on

  %  Plot 1-D Marginal PPDs
   maxppd=mmax(ppd1d);
   for i=1:mdim
       axes(ax(i,i))
       q=bar(modelgrid(i,:),ppd1d(i,:),1) ;set(q,'FaceColor',[0.8 0.8 0.8],'LineStyle','none');
	   hold on ; stairs(modelgrid(i,:)-delta(i)/bingrid/2,ppd1d(i,:),'k'); hold off
       hold on; plot([momin(i) momin(i)],[0 maxppd ],'k:') ; hold off
       if exist('msyn')  hold on; plot([msyn(i) msyn(i)],[0 maxppd],'r--') ; hold off ; end
	   if i~=mdim  set(gca,'XTickLabel','') ; end
	   title(ParNames(i))
       set(ax(i,i),'Xlim',bounds(i,:))
   end

  % plot contours of 2-D marginal ppds
   nint=plot_ninterp;
   for j=1:mdim
       for i=j+1:mdim
           axes(ax(i,j))
%           contour(modelgrid(j,:),modelgrid(i,:),ppd2d(:,:,i,j),4,'k')
                [xxnew,yynew]=meshgrid(linspace(bounds(j,1),bounds(j,2),nint),linspace(bounds(i,1),bounds(i,2),nint));
                [xxold,yyold]=meshgrid(modelgrid(j,:),modelgrid(i,:));
           contour('v6',interp2(xxold,yyold,ppd2d(:,:,i,j),xxnew,yynew),3,'k')
	       set(gca,'XTickLabel','','YTickLabel','') ; 
       end
   end
   for i=2:mdim
       set(ax(i,2:i),'yticklabel','')
   end
   
   for j=1:mdim
		   %  get axis tixk labels to plot on interpolated countours by generationg a temporary cotour plot
           pos=get(gca,'Position');tmp=axes('Position',pos);
		   if j~=mdim    
		          contour('v6',modelgrid(j,:),modelgrid(mdim,:),ppd2d(:,:,mdim,j),4,'k'); 
		      else          
			      contour('v6',modelgrid(j,:),modelgrid(1,:),ppd2d(:,:,j,1)',4,'k'); 
		   end
		   xt=get(gca,'XTick'); xtl=get(gca,'XTickLabel'); delete(tmp)
		   
      axes(ax(mdim,j))
	  xlabel(ParNames(j))
	       if j~=mdim set(gca,'XTick',(xt-bounds(j,1))*nint/delta(j),'XTickLabel',xtl) ; end
      axes(ax(j,1))
	  ylabel(ParNames(j))
	       set(gca,'YTick',(xt-bounds(j,1))*nint/delta(j),'YTickLabel',xtl)
   end	 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mhat=momin;
  momin=mhat;

% write model
  if exist('msyn')  s=sprintf( ['msyn   :  ' strParForm],gibbsopt.msyn); str0=char(str0,s); end

[str1,str2]=MakeStringForPlot(momin,inverseopt,objfuncopt,str0); 

strParNamesForm=list2str(inverseopt.ParNamesForm(inverseopt.freeind)); 
strParForm=list2str(inverseopt.ParForm(inverseopt.freeind));
s=sprintf(strParNamesForm,inverseopt.ParNames{inverseopt.freeind}); str0=char(str1,s) ;
s=sprintf(strParForm,momin)        ; str0=char(str0,s) ;
disp(str0)

  axes
 if WHAT=='PPD1D' set(gca,'NextPlot','add','Position',[0.1 -0.4 0.9 0.9],'vis','off')
  else set(gca,'NextPlot','add','Position',[1.5 1.5 18.0 2.0],'vis','off'); end
  text(0,0.5,str0,'Units','normalized','FontSize',7,'FontName','Courier')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [momin, ppd1d, ppd2d]=calc_ppd(models,energy,modelgrid)
%
% calc_ppd   calculates marginal probability distributions
%

mdim=size(modelgrid,1);
bingrid=size(modelgrid,2);
nmod=length(energy);
halfdel=(modelgrid(:,2)-modelgrid(:,1))/2;

% calculate mean (1st moment)
mmean=mean(models');
momin=models(:,find(energy==min(energy))) ; momin=momin(:,1) ;
 
%  calculate normalized 1D ppds at grid points 
   ppd1d=zeros(size(modelgrid));
  logmessage(sprintf('calculating 1-D marginal ppds...'))
   for i=1:mdim
       %logmessage(sprintf('calculating 1-D marginal ppds, parameter %d\r',i'))
       for j=1:bingrid
           list=find( models(i,:)>=modelgrid(i,j)-halfdel(i) & models(i,:)<modelgrid(i,j)+halfdel(i) );
           ppd1d(i,j)=length(list)/nmod;
       end
   end

if nargout==3
%  calculate normalized 2D ppds at grid points 
   ppd2d=zeros(bingrid,bingrid,size(models,1),size(models,1));
   logmessage(sprintf('calculating 2-D marginal ppds...'))
   for l=1:mdim
       for m=l+1:mdim
       %fprintf('calculating 2-D marginal ppds, parameter %d-%d\r',l,m')
           for i=1:bingrid
               for j=1:bingrid
                   list=find( (models(l,:)>=modelgrid(l,i)-halfdel(l) & models(l,:)<modelgrid(l,i)+halfdel(l)) & ...
                              (models(m,:)>=modelgrid(m,j)-halfdel(m) & models(m,:)<modelgrid(m,j)+halfdel(m)) );
                   ppd2d(j,i,m,l)=length(list)/nmod;
               end
           end
       end
   end
end         % end nargout if


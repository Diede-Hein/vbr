function fetch_data(datadirparent)
% sets up data directory and fetches all data for example
  fpath=what(datadirparent);
  datadir=fullfile(fpath.path,'data');
  if exist(datadir)==0
    mkdir(datadir);
  end

  % build all subdirectories
  subdirs={'LAB_models';'plate_VBR';'Q_models';'vel_models';'tmp'};
  for idir = 1:numel(subdirs)
    newdir=fullfile(datadir,subdirs{idir});
    if exist(newdir)==0
      mkdir(newdir);
    end
  end

  % check if the data is there
  fS=struct();

  fS(1).dir='vel_models'; fS(1).fname='Shen_Ritzwoller_2016.mat';
  fs(1).zipped=1;
  fS(2).dir='vel_models'; fS(2).fname='Porter_Liu_Holt_2015.mat';
  fs(2).zipped=1;
  fS(3).dir='Q_models'; fS(3).fname='Dalton_Ekstrom_2008.mat';
  fs(3).zipped=0;
  fS(4).dir='LAB_models'; fS(4).fname='HopperFischer2018.mat';
  fs(4).zipped=0;
  fS(5).dir='plate_VBR'; fS(5).fname='sweep_more.mat';
  fs(5).zipped=0;

  fetch_id=[];
  for iD = 1:numel(fS)
    fi=fullfile(datadir,fS(iD).dir,fS(iD).fname);
    if exist(fi)==0
      fS(iD).fetch_it=1;
      fetch_id=[fetch_id,iD];
    end
  end


  if sum(fetch_id)>0
    disp('attempting to fetch missing files')
    baseurl='https://github.com/vbr-calc/vbrPublicData/raw/master/LAB_fitting_bayesian/data';

    for niD = 1:numel(fetch_id)
      iD=fetch_id(niD);
      destFl=fullfile(datadir,fS(iD).dir,fS(iD).fname);
      disp(['fetching ',fS(iD).fname])
      pause(1)
      if fs(iD).zipped==0
        urlname=[baseurl,'/',fS(iD).dir,'/',fS(iD).fname];
        status=fetchOneFile(urlname,destFl);
      else
        [dir,nm,ext]=fileparts(destFl);
        urlname=[baseurl,'/',fS(iD).dir,'/',nm,'.zip'];
        tmpfil=fullfile(dir,[nm,'.zip']);
        status=fetchOneFile(urlname,tmpfil);
        % disp(['fetched ',urlname])
        % disp(['unzipping ',tmpfil])
        destDir=fullfile(datadir,fS(iD).dir);
        unzip(tmpfil,destDir);
        delete(tmpfil);
      end
    end

  end


end

function status = fetchOneFile(urlname,locfile)
  % attempts to fetch a file from a url
  status=0;
  try
  % first try with native matlab
    urlwrite(urlname,locfile);
  catch exception
    urlerror=exception;
    status=1;
  end

  if status==1
    % native matlab failed, try some other methods
    [locdir,nm,ext]=fileparts(locfile);
    wgetc=['wget --no-check-certificate -P ',locdir,' ',urlname];
    [status,results]=system(wgetc);

    if status>0
      msg=['Failed to fetch data for bayesian_fitting Project.\n\n'...
           'Native matlab command failed with: \n',
           urlerror.message, '\n',
           'Attempted to fetch data with wget, which failed with \n',
           results,'\n',
           'To get the data, you can \n ',
           '1. visit https://github.com/vbr-calc/vbrPublicData ',
           'and click "Clone or download"-> "Download zip".',
           '2. unpack the zip and move the contents of LAB_fitting_bayesian/data to ',
           'vbr/Projects/bayesian_fitting/data/'];
      urlerror.message=msg ;
      rethrow(urlerror);
    end
  end

end

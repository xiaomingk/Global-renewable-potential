using GlobalEnergyGIS, JLD, ImageTransformations
GE=GlobalEnergyGIS
#Average wind speed from GlobalWindAtlas (high spatial resolution);
averagespeed_Atlas=GE.readraster("Global Wind Atlas v3 - 100m wind speed.tif");
averagespeed_Atlas_clean=clamp!(averagespeed_Atlas, 0, 25)
saveTIFF(averagespeed_Atlas_clean, "averagewindspeed_Atlas.tif", [-180.0, -90.0, 180.0, 90.0])
#Average wind speed profile from ERA5 (low spatial resolution) for 2018;
averagespeed_ERA5=GE.h5read("era5wind2018.h5","meanwind");
saveTIFF(averagespeed_ERA5, "averagewindspeed_ERA5.tif", [-180.0, -90.0, 180.0, 90.0])
#Hourly wind speed profile from ERA5;
hourlyspeed =GE.h5read("era5wind2018.h5","wind");
JLD.save("hourlywindspeed.jld","hourlyspeed",hourlyspeed, compress=true)
#Parameter definition;
#Spatial resolution;
res = 0.01
#Spatial resolution of ERA6 data;
erares = 0.28125
#Spatial scope;
lonrange=1:36000
latrange=1:18000
options= GE.WindOptions("","",0,0,0,0,0,0,0,0,[],[],"",0,false,100,100,res,erares,[],[],[],[],0,0.0);
eralons, eralats, lonmap, latmap, cellarea = GE.eralonlat(options, lonrange, latrange);
#Scale up the wind speed from ERA5 to Global Wind Atlas;
rescale=zeros(36000,18000);
for i in 1:1280, j in 1:640
    eralon = eralons[i]
    eralat = eralats[j]
    rowrange = lonmap[GE.lon2row(eralon-erares/2, res):GE.lon2row(eralon+erares/2, res)-1]
    colrange = latmap[GE.lat2col(eralat+erares/2, res):GE.lat2col(eralat-erares/2, res)-1]
    for r in rowrange, c in colrange
        if averagespeed_ERA5[i,j]>0
        rescale[r,c]=averagespeed_Atlas[r,c]/averagespeed_ERA5[i,j]
        end
    end
end
saveTIFF(rescale,"windspeedscaleup.tif", [-180.0, -90.0, 180.0, 90.0])
#Calculate hourly wind capacity factor;
windspeed=zeros(36000,18000);
windCF=zeros(36000,18000);
function Capacit_factor(t)
for i in 1:1280, j in 1:640
    eralon = eralons[i]
    eralat = eralats[j]
    rowrange = lonmap[GE.lon2row(eralon-erares/2, res):GE.lon2row(eralon+erares/2, res)-1]
    colrange = latmap[GE.lat2col(eralat+erares/2, res):GE.lat2col(eralat-erares/2, res)-1]
    for r in rowrange, c in colrange
        windspeed[r,c]=hourlyspeed[t,i,j]*rescale[r,c]
        windCF[r,c]=GE.speed2capacityfactor(windspeed[r,c])
    end
end
return windCF
end
#Calculate average wind capacity factor;
windCF=sum(Capacit_factor(t) for t in 1:8760)/8760
saveTIFF(windCF,"windCF.tif", [-180.0, -90.0, 180.0, 90.0])

#Calculate average solar capacity factor from ERA5 for 2018;
hourlysolar =GE.h5read("era5solar2018.h5","GTI")
solarCFERA5=sum(hourlysolar[t,:,:] for t in 1:8760)/8760
solarCF =imresize(solarCFERA5,ratio=28.125)
saveTIFF(solarCF,"solarCF.tif", [-180.0, -90.0, 180.0, 90.0])

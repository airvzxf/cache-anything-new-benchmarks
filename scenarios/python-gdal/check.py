"""Writes a GeoTIFF, reprojects a point and converts a vector file with GDAL/OGR."""
import json
import os
import subprocess
import tempfile

import numpy as np
from osgeo import gdal, ogr, osr

gdal.UseExceptions()
work = tempfile.mkdtemp()

# Raster: write a 100x100 GeoTIFF in UTM zone 14N and read it back.
tif = os.path.join(work, "grid.tif")
srs = osr.SpatialReference()
srs.ImportFromEPSG(32614)
dataset = gdal.GetDriverByName("GTiff").Create(tif, 100, 100, 1, gdal.GDT_Float32)
dataset.SetGeoTransform((500000, 10, 0, 2200000, 0, -10))
dataset.SetProjection(srs.ExportToWkt())
dataset.GetRasterBand(1).WriteArray(np.arange(10000, dtype=np.float32).reshape(100, 100))
dataset = None
values = gdal.Open(tif).ReadAsArray()
assert values.shape == (100, 100) and values[99, 99] == 9999

# Projection: Mexico City from WGS 84 to UTM 14N needs the PROJ database.
wgs84 = osr.SpatialReference()
wgs84.ImportFromEPSG(4326)
wgs84.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
x, y, _ = osr.CoordinateTransformation(wgs84, srs).TransformPoint(-99.1332, 19.4326)
assert abs(x - 486000) < 1000 and abs(y - 2149000) < 1000, (x, y)

# Vector: GeoJSON to GeoPackage with the ogr2ogr command.
geojson = os.path.join(work, "points.geojson")
with open(geojson, "w", encoding="utf-8") as handle:
    json.dump({"type": "FeatureCollection", "features": [
        {"type": "Feature", "properties": {"name": "CDMX"},
         "geometry": {"type": "Point", "coordinates": [-99.1332, 19.4326]}}]}, handle)
gpkg = os.path.join(work, "points.gpkg")
subprocess.run(["ogr2ogr", "-f", "GPKG", gpkg, geojson], check=True)
source = ogr.Open(gpkg)  # keep a reference: the layer is freed with its data source
assert source.GetLayer(0).GetFeatureCount() == 1

print(f"GDAL {gdal.__version__}, NumPy {np.__version__}, UTM point ({x:.0f}, {y:.0f})")

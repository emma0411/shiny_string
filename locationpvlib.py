# -*- coding: utf-8 -*-
"""
Created on Wed Oct  6 10:56:45 2021

@author: eamoros
"""

import pvlib

def locationpvlib(lat, lon):
    
    data, _, elev, _ = pvlib.iotools.get_pvgis_tmy(lat = lat, lon = lon, outputformat = 'csv')
    
    return data
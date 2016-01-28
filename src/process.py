import numpy as np
import pandas as pd

conversion = {
    "object": "TEXT",
    "float64": "NUMERIC",
    "int64": "INTEGER"
}

tables = {
    "Country": "input/WDI_Country.csv",
    "CountryNotes": "input/WDI_CS_Notes.csv",
    "Indicators": "input/WDI_Data.csv",
    "Footnotes": "input/WDI_Footnotes.csv",
    "Series": "input/WDI_Series.csv",
    "SeriesNotes": "input/WDI_ST_Notes.csv",
}

sql = """.separator ","

"""

for table in tables:
    print(table)
    data = pd.read_csv(tables[table], encoding="latin1")
    data.columns = [''.join(x for x in col.title() if not x.isspace()).replace("-","") for col in data.columns]
    print(data.columns)
    if table=="Indicators":
        data = pd.melt(data, id_vars=["CountryName","CountryCode","IndicatorName", "IndicatorCode"], var_name="Year", value_name="Value")
        data = data[[not np.isnan(v) for v in data["Value"]]]
    if table=="Country":
        data = data.rename({"2AlphaCode": "Alpha2Code"})

    data.to_csv("output/%s.csv" % table, index=False)
    data = pd.read_csv("output/%s.csv" % table)

    sql += """CREATE TABLE %s (
%s);

.import "working/noHeader/%s.csv" %s

""" % (table,
       ",\n".join(["    %s %s%s" % (key,
                                   conversion[str(data.dtypes[key])],
                                   " PRIMARY KEY" if key=="Id" else "")
                   for key in data.dtypes.keys()]), table, table)

open("working/import.sql", "w").write(sql)

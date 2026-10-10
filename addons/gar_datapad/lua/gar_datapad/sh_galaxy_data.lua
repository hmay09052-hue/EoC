--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Galaxie-Daten (automatisch erzeugt, nicht von Hand bearbeiten)
    Quelle: swgalaxymap-Datensatz aus dem alten Datapad (planets.csv, hyperlanes_db.json)
    Koordinaten: 1 Rasterfeld = 100 Einheiten, Coruscant = 0/0, x nach rechts, y nach oben
    Zeilenformat: Name|x|y|Region|Sektor|kanonisch(1/0)
-------------------------------------------------------------------------------------------------------------]]

GAR_DP = GAR_DP or {}
GAR_DP.galaxyRaw = [==[
Xa Fel|-92.698|33.046|Core||1
Chazwa|199.857|106.001|Inner Rim|Orus|0
Azure|448.837|172.768|Mid Rim|Truum|0
Lwhekk|-815.269|-634.739|Unknown Regions||0
Xoman|701.869|63.523|Mid Rim|Halla|0
Prakith|-44.579|-88.82|Deep Core||1
Keeara Major|-7.337|-58.352|Deep Core||0
Symbia|-10.185|-51.878|Deep Core||0
Kuar|-1.898|-45.231|Deep Core||0
Odik|-76.85|-109.79|Deep Core||0
Byss|-48.074|-182.068|Deep Core||1
Kalist|-13.642|-202.323|Deep Core||1
Zamael|-13.411|-213.257|Deep Core||0
Lialic|-16.634|-226.839|Deep Core||0
Constancia|-14.059|-242.179|Deep Core||0
Dulvoyinn|-3.441|-246.927|Deep Core||0
Tython|1.279|-78.258|Deep Core||1
Had Abbadon|74.369|-78.834|Deep Core||0
Cambria|93.111|-58.448|Deep Core||0
Vulpter|58.406|-49.045|Deep Core||1
Besero|49.601|-38.168|Deep Core||0
Primus Goluud|36.48|-36.096|Deep Core||0
Empress Teta|1.987|-52.137|Deep Core||1
Iope|943.08|-225.899|Outer Rim|Baxel|0
Starswarm Cluster|9.756|-39.965|Deep Core||0
Jerrilek|1.946|-24.051|Deep Core||0
Tsoss Beacon|11.408|-105.307|Deep Core||0
Eclipse|99.245|-176.94|Deep Core||0
Crystan|13.406|-246.885|Deep Core||0
Khomm|12.507|-255.138|Deep Core||0
Dremulae|101.765|-73.526|Deep Core||0
Ojom|107.856|-163.279|Deep Core||1
Ottabesk|112.906|-159.264|Deep Core||0
Hakassi|113.302|-152.812|Deep Core||0
Ebaq|106.137|-143.229|Deep Core||0
Thoadeye|118.939|-112.328|Deep Core||0
Galactic Center|0|-142.091|Deep Core||0
Kokash|-110.308|-65.502|Core||0
Pollillus|-101.33|-63.89|Core||1
Osssorck Nebulae|-101.59|-266.91|Core||0
Questal|-117.741|-273.815|Core||1
Kitel Phard|-132.66|-286.761|Core||0
Inysh|-118.605|-295.761|Core||0
Dahrtag|-105.612|-314.795|Core||0
Metellos|-13.508|1.228|Core||0
Ragoon|-81.735|16.126|Core||0
Merakai|-61.722|51.288|Core||0
Denevar|-48.611|52.89|Core||0
Pantolomin|-37.227|44.441|Core||0
Dachat|-59.211|37.88|Core||0
Voon|-37.112|36.844|Core||0
Hyabb|-46.78|31.204|Core||0
Farrfin|-25.163|52.031|Core||0
Twith|-28.501|42.593|Core||0
Scipio|-64.533|481.957|Outer Rim|Albarrio|1
Galvoni|-15.034|29.587|Core||0
Weerden|-13.768|18.076|Core||0
Tanjay|-7.092|11.746|Core||0
Mamendin|-9.279|58.707|Core||0
Tamban|-95.23|-45.474|Core||0
Aradia|-90.281|-35|Core||0
Cal-Seti|-73.936|-34.194|Core||0
N'Zoth|-95.69|-57.768|Core||0
Fresia|-58.167|-29.475|Core||0
Galand|-53.563|-23.72|Core||0
Alland|-45.966|-14.397|Core||0
Worru'du|-38.6|-17.85|Core||0
Salliche|-25.709|-18.54|Core||0
Norkronia|-33.42|-6.829|Core||0
Stassia|-13.278|-11.433|Core||0
Foerost|-0.041|-7.404|Core||1
Ruan|-0.041|-13.85|Core||0
Galantos|-94.577|-55.855|Core||0
J't'p'tan|-96.605|-56.56|Core||0
Botor|-3.862|-270.404|Core||1
Thracior|-11.976|-275.982|Core||0
Thebeon|-31.435|-299.213|Core||0
Gerrard|-3.447|-295.268|Core||0
Daupherm|-18.489|-267.033|Core||0
Loedorvia|-87.534|-242.868|Core||0
Cortina|-60.163|-277.02|Core||0
Abregado-rae|-4.434|-316.721|Core||1
Dentaal|-4.31|-325.845|Core||0
Belgaroth|-11.955|-334.352|Core||0
Steelious|-18.612|-324.242|Core||0
Cuvacia|-93.206|-304.268|Core||0
Illodia|-73.016|-330.885|Core||0
Kidiet Olgo|5.338|61.419|Core||0
Challon|28.395|51.687|Core||0
Shawken|28.654|44.953|Core||0
Velusia|6.986|35.889|Core||1
Thorgeld|12.235|29.369|Core||0
Thokos|6.02|17.132|Core||0
Ralltiir|74.426|43.836|Core||1
Rhinnal|69.362|41.073|Core||0
Esseles|64.988|38.311|Core||0
Brentaal|60.499|35.894|Core||1
Chandrila|55.319|32.556|Core||1
Corulag|49.679|29.563|Core||1
Anaxes|41.047|24.959|Core||1
Grizmallt|28.386|17.708|Core||1
Alsakan|17.221|10.917|Core||1
Tepasi|89.481|18.076|Core||1
Skako|76.187|10.307|Core||1
Basilisk|60.924|6.866|Core||0
Spira|8.67|-16.777|Core||0
Yulant|34.421|-16.249|Core||0
Aargau|40.205|-19.875|Core||1
Broest|65.326|-24.45|Core||1
Ixtlar|37.098|-4.098|Core||0
Vultar|64.809|-5.306|Core||0
Wukkar|56.694|-12.471|Core||0
Kailor V|69.125|-20.068|Core||0
Palawa|92.548|-15.205|Core||0
Xorth|82.506|-28.363|Core||0
Gama|83.707|-246.323|Core||0
Balosar|67.596|-251.748|Core||1
Lansono|97.176|-277.948|Core||0
Lujo|49.337|-264.139|Core||0
Shulxi|61.79|-270.427|Core||0
Azbrian|61.667|-284.606|Core||0
Thomork|19.194|-266.62|Core||0
Frego|29.363|-306.429|Core||0
Iphigin|44.899|-327.883|Core||0
Andara|97.669|-315.8|Core||0
Eamus|5.307|-304.268|Core||0
Plexis|8.759|-311.173|Core||1
Diamal|10.115|-342.49|Core||0
Corann|101.371|35.211|Core||0
Korfo|106.703|8.252|Core||0
Caamas|113.696|7.086|Core||0
Aldraig|104.807|-19.867|Core||0
Alderaan|129.496|-5.968|Core||1
Vuma|112.651|-59.194|Core||0
Ator|107.472|-73.697|Core||1
Leria Kerlsil|125.312|-83.136|Core||0
Tyed Kant|145.455|-23.628|Core||0
Demophon|119.327|-33.181|Core||0
Glithnos|126.463|-41.584|Core||0
Fedalle|139.815|-54.475|Core||0
Raxxa|166.864|-55.511|Core||0
Kuat|186.813|-59.958|Core||1
Talravin|152.034|-74.474|Core||0
Pria|173.27|-83.711|Core||0
Ruul|143.574|-97.005|Core||0
Sarapin|160.062|-90.445|Core||0
Humbarine|188.233|-99.94|Core||0
Trellen|164.292|-100.458|Core||0
Mawan|168.781|-111.163|Core||0
Seyugi|187.312|-120.544|Core||0
Recopia|152.782|-123.766|Core||0
Loretto|176.838|-132.629|Core||0
Rendili|163.716|-140.801|Core||0
Perma|134.711|-106.731|Core||0
Lolnar|138.394|-117.551|Core||0
Columus|133.33|-129.521|Core||0
Lettow|126.726|-146.533|Core||0
Rehemsa|148.595|-151.022|Core||0
Sedratis|152.163|-162.187|Core||1
Baraboo|181.111|-146.907|Core||0
Bellassa|183.068|-152.777|Core||0
Jaciprus|186.866|-166.244|Core||0
Voktunma|188.708|-172.345|Core||0
Samaria|169.716|-169.237|Core||0
Rydonni Prime|155.098|-174.301|Core||0
Goorla|154.523|-180.287|Core||0
Sacorria|151.875|-184.545|Core||0
Corellia|157.553|-186.038|Core||1
Duro|157.102|-186.797|Core||1
Nubia|157.609|-186.709|Core||1
Karvoss|117.243|-205.225|Core||0
Hemei|103.763|-217.226|Core||0
Chasin|158.341|-249.447|Core||0
Chamm|105.407|-250.433|Core||0
Shumogi|114.284|-235.473|Core||0
Tinnel|170.506|-213.445|Core||1
Condular|151.108|-274.106|Core||0
Gandeal|146.043|-283.287|Core||0
Danteel|115.793|-261.304|Core||0
Kobaria|111.601|-265.126|Core||0
Sestria|102.724|-304.827|Core||0
Coruscant|0|0|Core||1
Thrantin|-145.977|49.154|Colonies|Ollonir Boundaries[|0
Batorine|-130.359|89.431|Colonies||0
Phu|-107.075|-374.057|Colonies||1
Trunska|-115.624|-357.946|Colonies||0
Candoria|-127.789|-335.424|Colonies||0
Hjaff|-127.46|-304.683|Colonies||0
Sif-Uwana|-67.725|111.459|Colonies||0
Vakkar|-94.686|97.157|Colonies|Fakir|0
Palanhi|-66.41|97.65|Colonies||0
Venjagga|-53.259|66.087|Colonies||0
Ord Mirit|-47.341|74.142|Colonies||0
Borleias|-41.258|63.128|Colonies||0
Noquivzor|-46.026|99.459|Colonies||0
Ophideraan|-11.234|-387.866|Colonies||0
Whelori|-28.66|-389.51|Colonies||0
Vaykaaris|-78.307|-384.742|Colonies||0
Zenox Cluster|-74.197|-361.892|Colonies||0
Omar|-53.483|-340.192|Colonies||0
Baradas|8.06|115.569|Colonies||0
Ord Antalaha|24.951|102.007|Colonies||0
Nierport|64.529|115.569|Colonies||0
Uviuy Exen|55.282|89.184|Colonies||0
Doldrums|84.749|88.321|Colonies||0
Delle|89.064|53.798|Colonies||0
Dankayo|47.761|99.664|Colonies||0
Kiribi|99.668|99.294|Colonies||0
Nara|27.91|66.744|Colonies||0
Wakeelmui|53.556|70.443|Colonies||0
Jatir|92.961|40.536|Colonies||0
Giju|3.068|-354.823|Colonies||1
Cilpar|1.26|-367.974|Colonies||0
Vindalia|14.247|-348.576|Colonies||0
Fondor|25.261|-369.618|Colonies||1
Ghorman|28.056|-397.729|Colonies||1
Mrlsst|29.042|-376.851|Colonies||0
Bassadro|62.249|-374.221|Colonies||0
Teyr Vulvarch|84.607|-380.961|Colonies||0
Laakteen Depot|3.232|-379.482|Colonies||0
Arkania|109.634|101.269|Colonies||0
Kluistar|104.631|109.1|Colonies||0
Raithal|149.412|85.716|Colonies||1
Castell|139.529|80.255|Colonies||1
Shulstine|133.755|77.81|Colonies||0
Ifmix|120.96|71.932|Colonies||0
Yabol Opa|109.256|64.858|Colonies||0
Teardrop|105.71|45.715|Colonies||0
Shelkonwa|116.683|43.126|Colonies||0
Belnar|129.012|62.113|Colonies||0
Argai Minor|140.972|52.496|Colonies||0
Carida|151.698|59.277|Colonies||1
Dakshee|153.671|50.893|Colonies||0
Hok|176.727|38.194|Colonies||1
Grandine|172.905|5.274|Colonies||0
Parkis|171.672|-24.07|Colonies||0
Kattada|191.03|-25.056|Colonies||0
Neimoidia|188.564|-59.984|Colonies||1
Balmorra|187.596|-58.187|Colonies||1
Exodeen|198.674|-207.779|Colonies||1
Loronar|184.248|-247.85|Colonies||0
Byblos|191.646|-264.125|Colonies||0
Pencael|198.674|-275.221|Colonies||0
Arat Fraca|178.207|-265.358|Colonies||0
Motexx|148.37|-322.813|Colonies||0
Froswythe|151.575|-332.677|Colonies||0
Enisca|126.67|-334.403|Colonies||0
Kelada|121.121|-353.267|Colonies|Kuluur|0
Devaron|120.382|-373.117|Colonies|Duluur|1
Belazura|136.533|-308.388|Colonies||0
Bryexx|129.629|-325.279|Colonies||0
Sanjin|114.073|-311.456|Colonies||0
Corroth|206.318|34.249|Colonies||0
Tibro|207.304|23.152|Colonies||0
Manwess|215.688|12.549|Colonies||0
Uquine|206.195|-33.687|Colonies||1
Resht|226.908|-25.426|Colonies||0
Xobome|234.059|-31.961|Colonies||0
Foundry|203.975|-74.991|Colonies||0
Faro|252.924|-71.415|Colonies||0
Commenor|231.1|-98.293|Colonies||1
Damoria|221.977|-107.91|Colonies||0
Chorax|215.072|-116.541|Colonies||0
Vladet|214.456|-129.61|Colonies||0
Cato Neimoidia|216.305|-135.158|Colonies||1
Hensara|218.278|-140.953|Colonies||0
Darek|248.238|-147.488|Colonies||0
Talasea|224.319|-155.872|Colonies||0
Vanjervalis|207.674|-193.107|Colonies||0
Lankashiir|234.676|-192.614|Colonies||0
Quellor|234.799|-209.382|Colonies||0
Boudolayz|201.14|-212.957|Colonies||0
Herzob|203.236|-219.739|Colonies||0
Besnia|207.428|-231.205|Colonies||0
Koensayr|210.264|-241.315|Colonies||0
Aquilae|215.195|-261.289|Colonies||0
Havricus|209.894|-291.373|Colonies||0
Virgillia|-247.289|-872.609|Outer Rim|Koradin|1
Lipsec|-275.842|-866.091|Outer Rim|Koradin|0
Coveway|-226.339|-818.45|Outer Rim|Koradin|0
Sump|-207.986|-891.331|Outer Rim|Koradin|1
Abridon|-133.386|-887.816|Outer Rim|Koradin|0
Keskin|-163.801|-893.093|Outer Rim|Koradin|0
Trenwyth|-285.213|-696.555|Outer Rim|Stensen|0
Gannaria|-375.84|-544.684|Outer Rim|Trilon|0
Zaddja|-377.081|-514.889|Outer Rim|Trilon|0
Rattatak|-370.046|-608.826|Outer Rim|Trilon|1
Abbaji|-315.836|-682.899|Outer Rim|Zuma|0
Firrerre|-361.356|-655.173|Outer Rim|Zuma|0
Houche|-345.631|-627.034|Outer Rim|Zuma|0
Annaj|-329.842|-697.931|Outer Rim|Moddell|0
Endor|-343.219|-683.025|Outer Rim|Moddell|1
Ast Kikorie|-347.7|-680.259|Outer Rim|Moddell|0
Sanyassa|-346.21|-685.71|Outer Rim|Moddell|0
Endor Gate|-343.775|-683.326|Outer Rim|Moddell|0
Murk|-340.262|-684.49|Outer Rim|Moddell|0
UR-3741|-343.3|-678.625|Outer Rim|Moddell|0
Zorbia|-340.433|-678.422|Outer Rim|Moddell|0
Din Pulsar|-339.812|-682.986|Outer Rim|Moddell|0
UR-1060|-338.578|-675.058|Outer Rim|Moddell|0
UR-2650|-335.562|-673.259|Outer Rim|Moddell|0
UR-9353|-332.81|-673.497|Outer Rim|Moddell|0
UR-8827|-334.424|-676.328|Outer Rim|Moddell|0
Vex|-329.512|-677.475|Outer Rim|Moddell|0
Vasha|-324.45|-676.037|Outer Rim|Moddell|0
Trindello|-335.097|-682.185|Outer Rim|Moddell|0
Qina|-329.444|-685.14|Outer Rim|Moddell|0
Maya Kovel|-322.714|-681.705|Outer Rim|Moddell|0
Kuna's Tail|-342.801|-688.917|Outer Rim|Moddell|0
Kuna's Horn|-338.003|-688.873|Outer Rim|Moddell|0
Kuna's Fist|-338.929|-690.611|Outer Rim|Moddell|0
Kuna's Eye|-337.227|-693.362|Outer Rim|Moddell|0
Kuna's Tooth|-334.943|-691.396|Outer Rim|Moddell|0
Thonner|-325.171|-689.05|Outer Rim|Moddell|0
Ovise|-327.596|-694.288|Outer Rim|Moddell|0
Timora|-403.979|-686.623|Outer Rim|Bakura|0
Bunduki|-375.012|-630.344|Outer Rim|Pacanth Reach|0
Lanteeb|-254.738|-749.55|Outer Rim|Bri'ahl|1
Imynusoph|-105.409|-1124.192|Outer Rim|Kallea|0
Terminus|-72.459|-1093.647|Outer Rim|Kallea|0
Delrakkin|-51.277|-1125.304|Outer Rim|Kallea|0
Cantros|-151.033|-1066.464|Outer Rim|Saijo|0
Faldos|-94.107|-1035.221|Outer Rim|Saijo|0
Saijo|-97.65|-1054.36|Outer Rim|Saijo|0
Barkhesh|-54.536|-974.433|Outer Rim|Seitia|0
Manpha|-79.675|-1014.271|Outer Rim|Seitia|0
Najarka|-146.421|-945.234|Outer Rim|Rayter|0
Absit|-216.873|-935.612|Outer Rim|Tunka|0
Thakwaa|-243.875|-918.853|Outer Rim|Tunka|0
Skye|-322.397|-992.098|Outer Rim|Varada|0
Fwatna|-27.534|-1051.515|Outer Rim|Subterrel|0
Polis Massa|-31.026|-1073.163|Outer Rim|Subterrel|1
Subterrel|13.201|-1094.776|Outer Rim|Subterrel|1
Quintas|-115.074|-913.266|Outer Rim|Kriz|0
Sil'Lume|-82.003|-967.915|Outer Rim|Kriz|0
Berrol's Donn|-82.753|-921.214|Outer Rim|Kriz|0
Elrood|156.609|-1005.098|Outer Rim|Elrood|0
Tarabba|162.137|-980.846|Outer Rim|Tarabba|0
Skustell Cluster|223.415|-959.708|Outer Rim|Tarabba|0
Utapau|205.724|-984.382|Outer Rim|Tarabba|1
Vestar|260.54|-1070.384|Outer Rim|Rseik|0
Cotellier|273.808|-1039.891|Outer Rim|Rseik|0
Taroon|292.197|-1003.578|Outer Rim|Rseik|0
Ma'ar Shaddam|274.041|-1019.174|Outer Rim|Rseik|0
Corva Yag|222.133|-1035.468|Outer Rim|Rseik|0
Swellen|96.321|-1013.478|Outer Rim|Airam|0
Skor|141.013|-1041.178|Outer Rim|Airam|0
Kal'Shebbol|165.9|-1127.83|Outer Rim|Kathol|0
Adarlon|162.641|-1055.903|Outer Rim|Minos|1
Karideph|162.408|-1069.869|Outer Rim|Minos|0
Pergitor|163.339|-1083.603|Outer Rim|Minos|0
Besberra|41.134|-1044.032|Outer Rim|Subterrel|0
Askaj|122.371|-1066.145|Outer Rim|Subterrel|1
Praesitlyn|161.788|-913.284|Outer Rim|Sluis|0
Sluis Van|160.741|-917.474|Outer Rim|Sluis|1
Denab|158.82|-934.408|Outer Rim|Sluis|0
Dagobah|164.058|-951.168|Outer Rim|Sluis|1
Queyta|179.796|-927.765|Outer Rim|Danjar|0
Shumavar|89.803|-923.162|Outer Rim|Atravis|0
Atravis|71.414|-945.741|Outer Rim|Atravis|0
Tosste|33.685|-989.33|Outer Rim|Atravis|1
Mustafar|17.856|-984.675|Outer Rim|Atravis|1
Dorlo|23.702|-928.042|Outer Rim|Atravis|0
Rutan|10.873|-1015.866|Outer Rim|Atravis|0
Kelrodo-Ai|62.346|-894.166|Outer Rim|Steniplis|0
Ryoone|-235.185|-795.406|Outer Rim|Wazta|0
Vassek|-207.718|-776.318|Outer Rim|Wazta|1
Koda Station|-279.179|-810.07|Outer Rim|Wazta|0
Cmaoli Di|183.261|-772.399|Outer Rim|Brema|0
Sullust|156.027|-781.302|Outer Rim|Brema|1
Bortras|144.33|-809.235|Outer Rim|Brema|0
Belsavis|40.589|-816.717|Outer Rim|Bozhnee|0
Ossel|43.861|-817.056|Outer Rim|Bozhnee|0
Garnib|49.311|-815.336|Outer Rim|Bozhnee|0
Dolla|25.051|-843.57|Outer Rim|Videnda|0
Dorvalla|139.442|-839.612|Outer Rim|Videnda|0
Lutrillia|-109.35|-843.916|Outer Rim|Javin|0
|-105.135|-857.888|Outer Rim|Javin|0
|-112.734|-843.585|Outer Rim|Javin|0
|-115.132|-837.482|Outer Rim|Javin|0
|-115.529|-814.725|Outer Rim|Javin|0
|-118.333|-826.208|Outer Rim|Javin|0
|-104.693|-830.911|Outer Rim|Javin|0
Shuldene|-114.703|-830.999|Outer Rim|Javin|0
|-103.976|-843.452|Outer Rim|Javin|0
|-100.016|-839.814|Outer Rim|Javin|0
Gerrenthum|-90.242|-840.709|Outer Rim|Javin|1
Bespin|-95.33|-849.857|Outer Rim|Javin|1
Hoth|-94.755|-858.69|Outer Rim|Javin|1
Isde Naha|-82.437|-890.816|Outer Rim|Javin|1
Javin|-82.324|-811.505|Outer Rim|Javin|0
Aztubek|-84.763|-815.345|Outer Rim|Javin|0
Kumru|-83.713|-820.434|Outer Rim|Javin|0
|-74.929|-813.78|Outer Rim|Javin|0
High Chunah|-84.569|-825.744|Outer Rim|Javin|0
Kirtarkin|-89.719|-830.982|Outer Rim|Javin|1
Mexeluine|-89.704|-835.802|Outer Rim|Javin|1
The Ring|-84.924|-838.073|Outer Rim|Javin|0
Council|-82.388|-840.776|Outer Rim|Javin|1
Nothoiin|-75.222|-843.09|Outer Rim|Javin|1
Saila Na|-70.275|-842.261|Outer Rim|Javin|0
Bavva|-65.711|-841.278|Outer Rim|Javin|1
Zephry|-69.744|-853.374|Outer Rim|Javin|0
Polmanar|-66.913|-863.242|Outer Rim|Javin|1
Delphon|-67.469|-868.296|Outer Rim|Javin|1
|-67.654|-871.048|Outer Rim|Javin|0
Tinoon|-66.066|-874.249|Outer Rim|Javin|1
|-69.138|-876.668|Outer Rim|Javin|0
Mev|-66.915|-883.062|Outer Rim|Javin|0
Togominda|-82.898|-897.783|Outer Rim|Javin|0
|-97.538|-894.747|Outer Rim|Javin|0
|-99.763|-882.838|Outer Rim|Javin|0
|-99.507|-871.406|Outer Rim|Javin|0
Mijos|-96.64|-834.897|Outer Rim|Javin|1
Indellian|-90.985|-845.786|Outer Rim|Javin|0
Varonat|-94.094|-847.937|Outer Rim|Javin|0
Anoat|-95.223|-854.071|Outer Rim|Javin|1
Bendeluum|-89.517|-849.679|Outer Rim|Javin|1
Ison|-91.156|-861.241|Outer Rim|Javin|1
Zhanox|-89.163|-853.907|Outer Rim|Javin|1
Ione|-87.474|-858.066|Outer Rim|Javin|1
Mataou|-88.722|-861.646|Outer Rim|Javin|1
Allyuen|-77.724|-857.391|Outer Rim|Javin|1
Burnin Konn|-81.706|-858.899|Outer Rim|Javin|1
Isis|-82.09|-863.11|Outer Rim|Javin|0
Tokmia|-78.386|-861.982|Outer Rim|Javin|1
Anantapar|-87.608|-864.511|Outer Rim|Javin|1
Shuxl|-87.449|-867.607|Outer Rim|Javin|0
Ertegas|-87.96|-870.579|Outer Rim|Javin|1
Darlyn Boda|-88.348|-873.507|Outer Rim|Javin|1
Orn Kios|-87.299|-880.642|Outer Rim|Javin|1
Ozu|-88.775|-886.01|Outer Rim|Javin|0
Bettel|-74.434|-888.603|Outer Rim|Javin|0
Eriadu|155.503|-829.311|Outer Rim|Seswenna|1
Averam|145.378|-846.42|Outer Rim|Seswenna|0
Darkknell|188.673|-754.591|Outer Rim|Grumani|0
Verdanth|271.015|-735.89|Outer Rim|Grumani|0
Sanrafsix|223.064|-742.873|Outer Rim|Grumani|0
Syned|218.409|-768.478|Outer Rim|Garis|0
Omwat|227.72|-803.394|Outer Rim|Garis|0
Bith|156.9|-876.797|Outer Rim|Mayagil|0
Triton|160.217|-885.526|Outer Rim|Mayagil|0
Xagobah|189.24|-871.103|Outer Rim|Mayagil|1
Kabal|233.772|-851.811|Outer Rim|Mayagil|0
Dravian Station|251.462|-890.684|Outer Rim|Tamarin|0
Kirdo|265.894|-940.264|Outer Rim|Tamarin|1
Sevarcos|229.349|-917.685|Outer Rim|Tamarin|1
Shadda-Bi Boran|323.622|-805.954|Outer Rim|Toblain|0
Rugosa|372.557|-757.029|Outer Rim|Sanbra|1
Sanbra|324.373|-757.901|Outer Rim|Sanbra|0
Arbra|279.861|-768.013|Outer Rim|Bon'nyuw-Luq|0
Sharlissia|285.447|-817.593|Outer Rim|Bon'nyuw-Luq|0
Svivren|360.88|-945.283|Outer Rim|Svivreni|0
Spice Terminus|437.229|-889.728|Outer Rim|Parmic|0
Elshandruu Pica|388.095|-876.266|Outer Rim|Quence|0
Suarbi|386.64|-915.178|Outer Rim|Quence|0
Vohai|376.573|-850.952|Outer Rim|Parmel|0
Skynara|485.122|-930.793|Outer Rim|Skine|0
Meryx Minor|365.885|-957.678|Outer Rim|Sujimis|0
Pantora|427.86|-936.031|Outer Rim|Sujimis|1
Alzoc|443.747|-943.363|Outer Rim|Sujimis|0
Karazak|470.458|-968.502|Outer Rim|Sujimis|0
Drexel|528.98|-854.968|Outer Rim|Dail|0
Nedij|532.419|-951.204|Outer Rim|Merel|0
Reuss|465.259|-846.588|Outer Rim|Cor'ric|0
Andalasa|469.623|-830.701|Outer Rim|Cor'ric|0
Zhar|493.89|-718.796|Outer Rim|Cadavine|0
Daan/Melida|461.503|-766.976|Outer Rim|Cadavine|0
Trigalis|409.592|-743.928|Outer Rim|Cadavine|0
Vergesso|436.803|-800.848|Outer Rim|Bajic|0
Bajic|429.994|-811.497|Outer Rim|Bajic|0
Stend|408.172|-752.315|Outer Rim|Juris|0
Bahalian|475.385|-812.545|Outer Rim|Astal|0
Socorro|515.189|-768.9|Outer Rim|Kiblini|1
Llanic|527.425|-695.681|Outer Rim|Karthakk|1
Lok|551.168|-721.286|Outer Rim|Karthakk|0
Christophsis|576.833|-676.034|Outer Rim|Savareen|1
Tythe|579.566|-699.871|Outer Rim|Savareen|0
Nelvaan|585.282|-699.026|Outer Rim|Savareen|1
Rodia|597.336|-664.554|Outer Rim|Savareen|1
Orvax|602.145|-744.796|Outer Rim|Savareen|0
Shimia|643.346|-756.9|Outer Rim|Dalchon|0
Dalchon|645.441|-742.701|Outer Rim|Dalchon|0
Tatooine|644.386|-673.274|Outer Rim|Arkanis|1
Geonosis|644.96|-673.297|Outer Rim|Arkanis|1
Austan|621.861|-658.048|Outer Rim|Arkanis|0
Pii|620.026|-649.81|Outer Rim|Arkanis|1
Utaruun|629.366|-666.814|Outer Rim|Arkanis|0
Vuzsa|642.419|-657.457|Outer Rim|Arkanis|0
Piroket|660.907|-642.275|Outer Rim|Arkanis|0
A-Foroon|660.017|-648.846|Outer Rim|Arkanis|0
B-Foroon|659.514|-651.218|Outer Rim|Arkanis|0
C-Foroon|658.905|-653.485|Outer Rim|Arkanis|0
New Ator|624.429|-692.396|Outer Rim|Arkanis|0
Kemal Station|629.235|-684.194|Outer Rim|Arkanis|0
Obana|648.241|-687.722|Outer Rim|Arkanis|0
Andooweel|637.195|-678.594|Outer Rim|Arkanis|1
Ooo-temiuk|651.848|-667.27|Outer Rim|Arkanis|0
Melnea's World|671.887|-682.384|Outer Rim|Arkanis|0
Cranan|663.001|-684.103|Outer Rim|Arkanis|0
Gedi|657.031|-692.182|Outer Rim|Arkanis|0
Vactooine|666.265|-698.497|Outer Rim|Arkanis|0
Arkanis|614.052|-708.852|Outer Rim|Arkanis|1
Gorno|627.069|-720.659|Outer Rim|Arkanis|0
Issor|622.577|-701.044|Outer Rim|Arkanis|0
Huldamun|625.099|-708.077|Outer Rim|Arkanis|0
Najiba|628.512|-704.77|Outer Rim|Arkanis|0
Tarnoonga|671.477|-704.26|Outer Rim|Arkanis|0
Cirus|673.958|-712.9|Outer Rim|Arkanis|0
Khubeaie|656.738|-715.451|Outer Rim|Arkanis|0
Heffrin|645.987|-718.626|Outer Rim|Arkanis|0
Vor Deo|650.094|-702.312|Outer Rim|Arkanis|0
Sirpar|622.786|-716.713|Outer Rim|Arkanis|1
Vasch|633.241|-715.906|Outer Rim|Arkanis|0
Mika|641.285|-715.267|Outer Rim|Arkanis|0
Siskeen|695.591|-702.744|Outer Rim|Hunnovers|0
Ryloth|671.278|-762.021|Outer Rim|Gaulus|1
Wrea|710.151|-793.213|Outer Rim|Gaulus|1
Gaulus|737.851|-775.522|Outer Rim|Gaulus|0
Smuggler's Run|729.418|-801.85|Outer Rim|Gaulus|1
Hypori|724.532|-645.211|Outer Rim|Ferra|1
Kowak|791.881|-602.07|Outer Rim|Svetta|1
Excarga|826.642|-660.108|Outer Rim|Svetta|0
Pzob|872.575|-585.621|Outer Rim|Herios|0
Illarreen|884.68|-613.243|Outer Rim|Herios|0
Rannon|817.032|-713.029|Outer Rim|Instrop|0
Shinbone|836.236|-735.898|Outer Rim|Instrop|0
Lo'Uran|686.449|622.162|Outer Rim|Corporate Sector|0
Ninn|698.63|619.119|Outer Rim|Corporate Sector|0
Reltooine|680.837|612.395|Outer Rim|Corporate Sector|0
Mall'ordian|693.696|610.988|Outer Rim|Corporate Sector|0
Knolstee|680.383|605.143|Outer Rim|Corporate Sector|0
Kail|681.203|600.513|Outer Rim|Corporate Sector|0
Davirien|684.396|600.698|Outer Rim|Corporate Sector|0
Drog|693.288|599.428|Outer Rim|Corporate Sector|0
Craci|695.193|587.981|Outer Rim|Corporate Sector|0
Bonadan|739.782|601.747|Outer Rim|Corporate Sector|1
Lythos|713.223|607.801|Outer Rim|Corporate Sector|0
D'ian|732.969|603.85|Outer Rim|Corporate Sector|0
|336.545|49.619|Inner Rim|Hapes Cluster|0
Atchorb|734.09|611.382|Outer Rim|Corporate Sector|0
Tothis|741.63|606.937|Outer Rim|Corporate Sector|0
R'alla|746.34|601.672|Outer Rim|Corporate Sector|0
Kir|748.606|603.083|Outer Rim|Corporate Sector|0
Deltooine|752.928|602.113|Outer Rim|Corporate Sector|0
Fether|756.112|602.721|Outer Rim|Corporate Sector|0
Ocsin|757.726|603.189|Outer Rim|Corporate Sector|0
Kamar|759.622|603.735|Outer Rim|Corporate Sector|0
Brosi|746.691|619.87|Outer Rim|Corporate Sector|0
Abo Dreth|739.794|622.145|Outer Rim|Corporate Sector|0
Ulicia|736.884|623.186|Outer Rim|Corporate Sector|0
Perin|721.847|631.909|Outer Rim|Corporate Sector|0
Fibuli|711.193|631.953|Outer Rim|Corporate Sector|0
Hiit|712.531|625.55|Outer Rim|Corporate Sector|0
Etti|730.248|598.133|Outer Rim|Corporate Sector|0
Jerrist|713.374|584.934|Outer Rim|Corporate Sector|0
Saclas|718.666|579.576|Outer Rim|Corporate Sector|0
Duroon|721.521|581.122|Outer Rim|Corporate Sector|0
Ammuud|731.778|577.193|Outer Rim|Corporate Sector|0
Biewa|728.537|586.387|Outer Rim|Corporate Sector|0
Urdur|735.28|580.13|Outer Rim|Corporate Sector|0
Oslumpex|739.01|581.047|Outer Rim|Corporate Sector|0
Matra|745.034|579.08|Outer Rim|Corporate Sector|0
Orron|747.51|576.267|Outer Rim|Corporate Sector|0
Joodrudda|756.471|582.758|Outer Rim|Corporate Sector|0
Gaurick|754.548|584.716|Outer Rim|Corporate Sector|0
Ban-Satir|751.426|589.526|Outer Rim|Corporate Sector|0
Pondut Station|736.222|587.798|Outer Rim|Corporate Sector|0
Kalla|734.034|589.526|Outer Rim|Corporate Sector|0
Issagra|747.616|595.418|Outer Rim|Corporate Sector|0
Saffalore|736.574|594.465|Outer Rim|Corporate Sector|0
Erysthes|744.609|599.051|Outer Rim|Corporate Sector|0
Rampa|747.555|599.236|Outer Rim|Corporate Sector|0
Media|722.498|590.867|Outer Rim|Corporate Sector|0
Ession|730.013|593.089|Outer Rim|Corporate Sector|0
Maryo|713.655|596.803|Outer Rim|Corporate Sector|0
Tirsa|715.666|594.396|Outer Rim|Corporate Sector|0
Cadomai|668.17|612.862|Outer Rim|Aparo|0
Lur|671.775|595.847|Outer Rim|Aparo|0
Kushibah|486.027|462.297|Outer Rim|Gordian Reach|0
Feswe Prime|411.585|417.05|Outer Rim|Gordian Reach|0
Feswe Minor|406.91|406.819|Outer Rim|Gordian Reach|0
Krylon|441.394|401.616|Outer Rim|Gordian Reach|0
Ladarra|453.565|414.227|Outer Rim|Gordian Reach|0
Marrovia|463.531|424.017|Outer Rim|Gordian Reach|0
Kli'aar|475.967|430.896|Outer Rim|Gordian Reach|0
Mogoshyn|483.704|452.774|Outer Rim|Gordian Reach|0
Betshish|485.204|440.78|Outer Rim|Gordian Reach|0
Vaal|487.408|400.034|Outer Rim|Gordian Reach|0
Glade|491.554|413.44|Outer Rim|Gordian Reach|0
Feswe Corridor|428.43|412.023|Outer Rim|Gordian Reach|0
Torque|461.36|381.023|Outer Rim|Gordian Reach|0
Yavin|458.395|398.671|Outer Rim|Gordian Reach|1
Tertiary Feswe|404.845|393.836|Outer Rim|Gordian Reach|0
Selitan|417.051|388.051|Outer Rim|Gordian Reach|0
Denarii Station|422.625|377.82|Outer Rim|Gordian Reach|0
|432.379|382.577|Outer Rim|Gordian Reach|0
Presbalin|417.386|367.407|Outer Rim|Gordian Reach|0
Far Indosa|432.069|357.3|Outer Rim|Gordian Reach|0
Near Indosa|442.441|368.307|Outer Rim|Gordian Reach|0
Trinovat|455.458|366.19|Outer Rim|Gordian Reach|0
Durgen's Star|471.757|358.676|Outer Rim|Gordian Reach|0
Jovan|481.282|379.208|Outer Rim|Gordian Reach|0
Xochtl|487.314|362.592|Outer Rim|Gordian Reach|0
Povanaria|492.606|354.548|Outer Rim|Gordian Reach|0
Bronsoon|497.262|365.026|Outer Rim|Gordian Reach|0
Feena|549.753|407.225|Outer Rim|Gordian Reach|0
Troos|535.889|460.213|Outer Rim|Gordian Reach|0
Mannova|502.313|448.982|Outer Rim|Gordian Reach|0
Wetyin's Colony|513.867|429.932|Outer Rim|Gordian Reach|0
Atorra|539.924|450.722|Outer Rim|Gordian Reach|0
Elamposnia|546.909|451.074|Outer Rim|Gordian Reach|0
Chenowei|544.157|439.433|Outer Rim|Gordian Reach|0
B'trilla|547.332|426.168|Outer Rim|Gordian Reach|0
Arda|556.434|382.187|Outer Rim|Gordian Reach|0
|336.142|53.439|Inner Rim|Hapes Cluster|0
Vallusk Cluster|501.355|383.106|Outer Rim|Gordian Reach|0
Gulvitch|505.235|369.083|Outer Rim|Gordian Reach|0
Arkuda|508.498|372.611|Outer Rim|Gordian Reach|0
Korphir|522.61|367.495|Outer Rim|Gordian Reach|0
Tenara|526.667|361.939|Outer Rim|Gordian Reach|0
The Cometwash|527.725|377.638|Outer Rim|Gordian Reach|0
Usta|531.517|392.19|Outer Rim|Gordian Reach|0
Barison|538.749|398.804|Outer Rim|Gordian Reach|0
Little Capella|559.828|361.939|Outer Rim|Gordian Reach|0
Capella|555.33|371.993|Outer Rim|Gordian Reach|0
Kalishik|550.038|392.543|Outer Rim|Gordian Reach|0
Feldwes|577.643|383.018|Outer Rim|Gordian Reach|0
Pygorix|585.933|385.222|Outer Rim|Gordian Reach|0
Karsten's World|588.756|378.52|Outer Rim|Gordian Reach|0
Spintir|595.282|388.486|Outer Rim|Gordian Reach|0
Sorrus|391.597|418.772|Outer Rim|Kalamith|0
Hynah|396.768|425.869|Outer Rim|Kalamith|0
Simpla|401.885|432.502|Outer Rim|Kalamith|0
Toprawa|409.209|443.249|Outer Rim|Kalamith|0
Pho Ph'eah|430.753|475.322|Outer Rim|Kalamith|0
Tandun|432.857|453.068|Outer Rim|Kalamith|0
Thesme|366.06|407.23|Outer Rim|Thesme|0
Junction|383.513|406.384|Outer Rim|Thesme|0
Hijado|357.642|369.746|Outer Rim|Thesme|0
Axxila|313.01|415.331|Outer Rim|D'Astan|1
Nez Peron|345.385|414.248|Outer Rim|D'Astan|0
Ord Cestus|329.052|390.712|Outer Rim|D'Astan|1
Celanon|369.078|388.965|Outer Rim|D'Astan|1
Serenno|408.588|463.003|Outer Rim|D'Astan|1
Maridun|512.719|355.977|Outer Rim|Rolion|1
Indu San|541.139|278.517|Outer Rim|Rolion|0
Soullex|405.998|649.432|Outer Rim|Corva|0
Eol Sha|411.08|607.359|Outer Rim|Corva|0
Ventooine|475.192|621.642|Outer Rim|Corva|0
Betha|424.894|576.939|Outer Rim|Corva|0
Bosph|519.488|649.79|Outer Rim|Bosph|0
Belkadan|62.096|809.383|Outer Rim|Dalonbian|1
Helska|50.236|731.167|Outer Rim|Dalonbian|0
Sernpidal|70.355|693.099|Outer Rim|Dalonbian|0
Seline|115.042|674.833|Outer Rim|Dalonbian|0
Birgis|182.538|649.997|Outer Rim|Dalonbian|0
Xo|206.668|725.52|Outer Rim|Spinward|0
Bextar|-113.612|514.828|Outer Rim|Velcar|0
Ryloon|-132.095|492.244|Outer Rim|Velcar|0
Endex|-111.633|498.418|Outer Rim|Velcar|0
Churruma|-122.12|489.113|Outer Rim|Velcar|0
Entralla|-92.007|520.908|Outer Rim|Velcar|1
Capza|-93.289|514.028|Outer Rim|Velcar|0
Taspir III|-137.177|598.904|Outer Rim|Dynali|0
Ord Thoden|-142.881|585.91|Outer Rim|Dynali|0
Vexta|-141.778|576.429|Outer Rim|Carrion|0
Delephr|-132.521|567.039|Outer Rim|Carrion|0
Gelda|-123.066|555.468|Outer Rim|Carrion|0
Valc|-159.141|516.92|Outer Rim|Perinn|0
Brodo Asogi|-174.149|526.54|Outer Rim|Perinn|0
Cantras Gola|-153.829|505.938|Outer Rim|Perinn|0
Dactruria|-125.465|534.583|Outer Rim|Clacis|0
Bisellia|-86.801|543.897|Outer Rim|Clacis|0
Endoraan|-89.341|535.853|Outer Rim|Clacis|0
Cezith|-75.604|530.713|Outer Rim|Clacis|0
Ord Sedra|-79.978|538.051|Outer Rim|Clacis|0
Venestria|-55.989|542.708|Outer Rim|Clacis|0
Kwevron|-34.54|537.063|Outer Rim|Clacis|0
Fodro|-17.325|524.646|Outer Rim|Clacis|0
Gwori|-4.625|520.977|Outer Rim|Clacis|0
Dolis|-112.895|615.675|Outer Rim|Obtrexta|0
Bescane|-88.161|608.76|Outer Rim|Obtrexta|0
Varvrona|-98.783|600.021|Outer Rim|Obtrexta|0
Muunilinst|-80.501|550.31|Outer Rim|Obtrexta|1
Jaemus|-86.043|587.795|Outer Rim|Obtrexta|1
|356.469|59.198|Inner Rim|Hapes Cluster|0
Rimcee Station|-116.863|641.031|Outer Rim|Braxant|0
Bastion|-89.29|646.65|Outer Rim|Braxant|0
Anorelga|-83.129|672.12|Outer Rim|Braxant|0
Bnar|-57.552|630.668|Outer Rim|Braxant|0
Dubrillion|-33.24|624.432|Outer Rim|Myto|0
Criton's Point|-42.118|649.41|Outer Rim|Myto|0
Ahakista|-30.549|615.041|Outer Rim|Myto|1
Gabredor|-44.585|569.21|Outer Rim|Myto|0
Angor|-19.009|562.508|Outer Rim|Myto|0
Cirrus|-124.55|349.122|Outer Rim|Dantus|0
Troska|-147.704|372.277|Outer Rim|Dantus|0
Comra|-129.709|408.604|Outer Rim|Prefsbelt|1
Borosk|-94.266|456.458|Outer Rim|Prefsbelt|0
Yaga Minor|-96.066|479.613|Outer Rim|Prefsbelt|1
Ompersan|-96.72|475.037|Outer Rim|Prefsbelt|0
Prefsbelt|-94.709|465.089|Outer Rim|Prefsbelt|1
Wistril|-48.311|382.442|Outer Rim|Fath|0
JanFathal|-54.24|389.219|Outer Rim|Fath|0
Ord Cantrell|-15.211|374.818|Outer Rim|Fath|0
Equanus|-10.615|637.137|Outer Rim|Veragi|0
Revyia|21.717|758.274|Outer Rim|Veragi|0
Plooma|41.9|654.503|Outer Rim|Veragi|0
Trassitan|22.956|662.108|Outer Rim|Veragi|0
Veragi|39.272|673.265|Outer Rim|Veragi|0
Plesstil|38.919|684.906|Outer Rim|Veragi|0
Dantooine|0.98|558.551|Outer Rim|Raioballo|1
Gravlex Med|68.077|561.19|Outer Rim|Raioballo|0
Anx Minor|28.69|541.204|Outer Rim|Raioballo|0
Sinsang|19.091|546.985|Outer Rim|Raioballo|0
Kesmere|28.44|557.921|Outer Rim|Raioballo|0
Kesmere Minor|24.559|572.033|Outer Rim|Raioballo|0
Tertiary Kesmere|20.679|587.026|Outer Rim|Raioballo|0
Shusugaunt|43.786|582.792|Outer Rim|Raioballo|0
Ibanjji|293.474|582.581|Outer Rim|Mieru'kar|0
Maltha Obex|352.065|612.442|Outer Rim|Mieru'kar|0
Neelgaimon|566.573|624.218|Outer Rim|Xappyh|0
Ruuria|579.915|607.7|Outer Rim|Xappyh|1
Tiss'sharl|618.035|597.323|Outer Rim|Xappyh|0
Iliabath|676.35|524.589|Outer Rim|Mortex|0
Ranroon|685.115|484.444|Outer Rim|Mortex|0
Almania|717.119|494.43|Outer Rim|Mortex|0
Troiken|761.592|498.243|Outer Rim|Colundra|1
Zygerria|706.318|547.586|Outer Rim|Chorlian|1
Vaynai|745.709|523.673|Outer Rim|Chorlian|0
|337.021|54.54|Inner Rim|Hapes Cluster|0
Ziost|617.998|518.502|Outer Rim|Sith Worlds|1
Begeren|618.162|501.35|Outer Rim|Sith Worlds|0
Korriz|605.379|523.672|Outer Rim|Sith Worlds|0
Athiss|616.739|526.353|Outer Rim|Sith Worlds|0
Svolten|641.645|527.27|Outer Rim|Sith Worlds|0
Bhargebba|638.117|523.46|Outer Rim|Sith Worlds|0
Ch'hodos|630.427|513.371|Outer Rim|Sith Worlds|0
Nfolgai|648.903|516.969|Outer Rim|Sith Worlds|0
Krayiss|653.066|506.174|Outer Rim|Sith Worlds|0
Korriban|616.975|466.096|Outer Rim|Sith Worlds|1
Bosthirda|624.792|477.327|Outer Rim|Sith Worlds|0
Dromund Kaas|635.376|483.677|Outer Rim|Sith Worlds|0
Nicht Ka|607.365|487.064|Outer Rim|Sith Worlds|0
Rhelg|655.212|481.109|Outer Rim|Sith Worlds|0
Khar Delba|660.398|493.439|Outer Rim|Sith Worlds|0
Jaguada|639.337|490.264|Outer Rim|Sith Worlds|0
Ashas Ree|621.866|491.957|Outer Rim|Sith Worlds|0
Kalsunor|614.061|496.543|Outer Rim|Sith Worlds|0
Elom|631.561|422.002|Outer Rim|Sertar|0
Syngia|685.776|449.957|Outer Rim|Sertar|0
Yutusk|694.904|457.192|Outer Rim|Sertar|0
Sembla|716.711|435.23|Outer Rim|Sertar|1
Telos|507.946|570.992|Outer Rim|Kwymar|1
Doniphon|515.411|579.728|Outer Rim|Kwymar|0
Tantive|522.4|585.446|Outer Rim|Kwymar|0
Listehol|535.265|591.323|Outer Rim|Kwymar|0
Thila|525.577|532.078|Outer Rim|I-Sector|0
Ferro|539.395|547.961|Outer Rim|I-Sector|0
Mirial|544.319|564.956|Outer Rim|I-Sector|1
Sikurd|561.155|545.42|Outer Rim|I-Sector|0
Ord Radama|503.499|490.782|Outer Rim|Esstran|1
Thule|589.721|492.952|Outer Rim|Esstran|0
Corbos|604.666|452.651|Outer Rim|Esstran|0
Thosa|644.93|573.816|Outer Rim|Tynquay|0
Gigor|629.103|558.045|Outer Rim|Tynquay|0
Dra|691.886|584.77|Outer Rim|Wyl|0
Lafra|680.187|575.942|Outer Rim|Wyl|0
Praadost|460.455|516.512|Outer Rim|Nembus|0
Carosi|467.92|552.567|Outer Rim|Nembus|0
Thalassia|438.854|535.414|Outer Rim|Meram|0
Tangrene|350.971|506.818|Outer Rim|Morshdine|0
Edusa|363.042|483.152|Outer Rim|Morshdine|0
Camden|358.436|465.839|Outer Rim|Morshdine|0
Vandyne|353.354|444.874|Outer Rim|Morshdine|0
Salin|275.844|422.161|Outer Rim|Sprizen|0
Toola|779.805|463.934|Outer Rim|Nilgaard|1
Quermia|761.75|462.981|Outer Rim|Nilgaard|1
Makem Te|749.467|447.84|Outer Rim|Nilgaard|0
Emmer|750.996|477.3|Outer Rim|Nilgaard|0
Janodral Mizar|735.65|425.795|Outer Rim|Indrexu|0
Raxus|770.01|411.043|Outer Rim|Tion Hegemony|1
Tion|773.045|407.979|Outer Rim|Tion Hegemony|0
Endregaad|757.522|413.8|Outer Rim|Tion Hegemony|0
Livien|718.011|403.217|Outer Rim|Tion Hegemony|0
Kanaver|724.008|406.039|Outer Rim|Tion Hegemony|0
Desevro|719.394|398.44|Outer Rim|Tion Hegemony|0
Rudrig|791.036|389.635|Outer Rim|Tion Hegemony|1
Caluula|814.008|331.357|Outer Rim|Tion Hegemony|0
Dellalt|827.631|320.22|Outer Rim|Tion Hegemony|0
Brigia|811.041|342.91|Outer Rim|Tion Hegemony|0
Eredenn|801.71|361.695|Outer Rim|Tion Hegemony|0
Mullan|819.59|352.681|Outer Rim|Keldrath|0
Chandaar|708.932|348.757|Outer Rim|Cronese Mandate|0
Algor|791.744|330.739|Outer Rim|Cronese Mandate|0
Pasmin|729.346|336.912|Outer Rim|Cronese Mandate|0
Duinarbulon|749.498|338.941|Outer Rim|Cronese Mandate|0
Eibon|779.661|337.353|Outer Rim|Cronese Mandate|0
Derellium|766.432|343.88|Outer Rim|Cronese Mandate|0
Corlass|775.957|358.873|Outer Rim|Cronese Mandate|0
Nuswatta|786.54|356.756|Outer Rim|Cronese Mandate|0
Argai|778.073|369.456|Outer Rim|Cronese Mandate|0
Jaminere|763.87|372.235|Outer Rim|Allied Tion|0
Cadinth|728.557|360.64|Outer Rim|Allied Tion|0
Lianna|704.624|371.071|Outer Rim|Allied Tion|1
Barseg|710.984|380.643|Outer Rim|Allied Tion|0
Amarin|737.372|384.17|Outer Rim|Allied Tion|0
Felucia|680.216|379.912|Outer Rim|Thanium|1
Galidraan|682.598|359.105|Outer Rim|Thanium|1
Draukyze|669.083|351.394|Outer Rim|Thanium|0
Mossak|679.375|369.918|Outer Rim|Thanium|0
Arcan|699.695|364.979|Outer Rim|Thanium|0
Thanium|692.216|386.852|Outer Rim|Thanium|0
Rhen Var|662.797|353.175|Outer Rim|Belderone|1
Belderone|677.801|312.544|Outer Rim|Belderone|1
Vorzyd|615.043|344.069|Outer Rim|Vorzyd|0
Columex|675.472|327.791|Outer Rim|Vorzyd|0
Antemeridias|644.092|272.432|Outer Rim|Antemeridian|0
Nam Chorios|636.22|304.466|Outer Rim|Meridian|1
Budpock|654.77|293.325|Outer Rim|Meridian|0
Lucazec|563.935|328.817|Outer Rim|Nuiri|1
Vjun|546.252|313.887|Outer Rim|Nuiri|1
Gala|542.916|299.91|Outer Rim|Nuiri|0
Garqi|-39.212|446.258|Outer Rim|Cassander|0
Cassander|-18.814|436.905|Outer Rim|Cassander|0
Ord Canfre|-26.224|414.138|Outer Rim|Cassander|1
Monhudle|-62.924|445.13|Outer Rim|Cassander|0
Forsen|-23.13|424.105|Outer Rim|Cassander|0
New Bakstre|-8.455|432.572|Outer Rim|Cassander|0
Biitu|-43.027|456.137|Outer Rim|Cassander|0
Minashee|-55.303|461.782|Outer Rim|Cassander|0
Isiring|18.78|425.234|Outer Rim|Cassander|0
Kalki Nebula|2.27|440.756|Outer Rim|Cassander|0
Moltok|7.237|458.399|Outer Rim|Atrivis|1
Horuz|71.159|469.923|Outer Rim|Atrivis|1
Generis|86.194|451.34|Outer Rim|Atrivis|0
Fedje|74.123|425.891|Outer Rim|Atrivis|0
Spefik|25.377|448.447|Outer Rim|Atrivis|0
Vuchelle|57.938|423.223|Outer Rim|Atrivis|0
Iridium|59.35|440.439|Outer Rim|Atrivis|0
Gibbela|32.679|460.053|Outer Rim|Atrivis|0
Fest|80.499|439.786|Outer Rim|Atrivis|1
Devon|83.885|445.148|Outer Rim|Atrivis|0
Markbee's Star|83.462|457.848|Outer Rim|Atrivis|0
Hethar|92.352|457.989|Outer Rim|Atrivis|0
|341.582|52.286|Inner Rim|Hapes Cluster|0
Nam'ta|87.413|467.02|Outer Rim|Atrivis|0
Mantooine|55.804|472.665|Outer Rim|Atrivis|0
Bimmiel|232.006|561.615|Outer Rim|Kanz|0
Ereesus|257.737|540.491|Outer Rim|Kanz|0
Jerne|235.977|529.69|Outer Rim|Kanz|0
Argazda|250.272|524.925|Outer Rim|Kanz|0
Lorrd|274.573|544.303|Outer Rim|Kanz|0
Kol Huro|274.573|531.278|Outer Rim|Kanz|0
Shaum Hii|217.711|455.515|Outer Rim|Tragan Cluster|0
Agamar|145.739|419.714|Outer Rim|Lahara|1
Gandolo|149.079|469.419|Outer Rim|Lahara|0
Ketaris|96.835|408.245|Outer Rim|Oplovis|0
Akuria|134.447|488.259|Outer Rim|Oplovis|0
Phaeda|55.664|366.912|Outer Rim|Cademimu|0
Cademimu|133.315|371.712|Outer Rim|Cademimu|0
Noonar|119.479|339.804|Outer Rim|Halthor|0
Ord Trasi|14.957|511.324|Outer Rim|Relgim|0
Ord Biniir|1.166|466.658|Outer Rim|Relgim|0
Vykos|5.253|486.828|Outer Rim|Relgim|0
Marmoth|-62.904|516.179|Outer Rim|Albarrio|0
Mygeeto|-50.923|493.977|Outer Rim|Albarrio|1
Anemcoro|-3.516|461.499|Outer Rim|Albarrio|0
Haverling|-32.302|478.151|Outer Rim|Albarrio|0
Morishim|-31.315|489.157|Outer Rim|Albarrio|0
Aris|-31.153|497.552|Outer Rim|Albarrio|0
Malestrom Nebula|-11.257|488.944|Outer Rim|Albarrio|0
Eridicon|877.697|336.045|Outer Rim|Calamari|0
Minntooine|897.752|322.128|Outer Rim|Calamari|0
Ruisto|900.284|336.088|Outer Rim|Calamari|0
Mon Calamari|907.208|330.121|Outer Rim|Calamari|1
New Heurkea|916.585|309.58|Outer Rim|Calamari|0
Mantan|911.54|314.202|Outer Rim|Calamari|0
Hinakuu|945.812|304.853|Outer Rim|Calamari|0
Krinemonen|940.662|321.204|Outer Rim|Calamari|0
Buchich|951.386|325.544|Outer Rim|Calamari|0
Pammant|910.323|325.455|Outer Rim|Calamari|1
Pinperu|924.934|332.887|Outer Rim|Calamari|0
Damendine|924.404|348.357|Outer Rim|Calamari|0
Kamdon|928.787|290.578|Outer Rim|Calamari|0
Poseidenna|901.45|294.658|Outer Rim|Calamari|0
Sanctuary|920.112|295.469|Outer Rim|Calamari|0
Wyndigal|752.55|290.804|Outer Rim|Ash Worlds|0
Altratonne|771.6|263.552|Outer Rim|Ash Worlds|0
New Alderaan|868.824|306.305|Outer Rim|Ash Worlds|1
Cophrigin|832.29|269.833|Outer Rim|Ash Worlds|0
Iego|827.649|249.558|Outer Rim|Ash Worlds|1
OHS1782-03|815.521|229.421|Outer Rim|Ash Worlds|0
Agon|814.498|245.948|Outer Rim|Ash Worlds|0
OHS3842-03|807.054|269.373|Outer Rim|Ash Worlds|0
OHS4140-02|816.015|285.071|Outer Rim|Ash Worlds|0
OHS2132-04|874.664|299.694|Outer Rim|Ash Worlds|0
Chiron|894.409|262.814|Outer Rim|Ash Worlds|0
Nyny|838.241|276.422|Outer Rim|Ash Worlds|0
Baros|942.665|256.315|Outer Rim|Dominus|0
Dornea|939.864|282.817|Outer Rim|Dominus|0
Gand|872.685|177.441|Outer Rim|Shadola|1
Skeebo|924.148|176.384|Outer Rim|Shadola|0
Maldra|932.063|190.414|Outer Rim|Shadola|0
Baummu|922.834|177.814|Outer Rim|Shadola|0
Jubilar|817.625|218.579|Outer Rim|Jubilar|0
Toong'l|886.028|225.992|Outer Rim|Jubilar|0
Oseon|860.614|150.898|Outer Rim|Centrality|0
Erilnar|863.535|148.974|Outer Rim|Centrality|0
Rafa|871.986|149.117|Outer Rim|Centrality|0
Ringneldia|893.706|155.471|Outer Rim|Centrality|0
Arleen|870.837|153.689|Outer Rim|Centrality|0
Scillal|866.604|143.591|Outer Rim|Centrality|0
Lekua|874.436|139.199|Outer Rim|Centrality|0
Cadma|881.597|135.477|Outer Rim|Centrality|0
Zebitrope|886.712|127.319|Outer Rim|Centrality|0
Dela|872.651|145.538|Outer Rim|Centrality|0
Tund|955.544|145.444|Outer Rim|Centrality|1
ThonBoka|919.968|129.403|Outer Rim|Centrality|0
Renatasia|909.306|124.107|Outer Rim|Centrality|0
Hosrel|930.695|135.415|Outer Rim|Centrality|0
Trammis|934.293|144.27|Outer Rim|Centrality|0
Douglas|947.796|134.119|Outer Rim|Centrality|0
Paulking|943.571|140.883|Outer Rim|Centrality|0
Antipose|937.098|148.221|Outer Rim|Centrality|0
Falko|933.288|149.773|Outer Rim|Centrality|0
Uaua|924.486|151.625|Outer Rim|Centrality|0
|356.215|60.224|Inner Rim|Hapes Cluster|0
Dilonexa|913.25|155.365|Outer Rim|Centrality|0
Dagelin Minor|834.181|157.907|Outer Rim|Cadma|0
Taskeed|758.752|208.343|Outer Rim|Tharin|0
Dennogra|776.153|190.447|Outer Rim|Tharin|1
Junkfort Station|805.955|163.226|Outer Rim|Tharin|0
Tammar|805.424|119.018|Outer Rim|Tharin|0
Nimat|805.73|153.559|Outer Rim|Tharin|0
Af'El|773.879|118.911|Outer Rim|Periphery|0
Vaathkree|770.702|114.464|Outer Rim|Periphery|0
Sriluur|775.679|112.982|Outer Rim|Periphery|1
Lant|764.624|107.602|Outer Rim|Periphery|0
Yoribuunt|798.667|101.841|Outer Rim|Periphery|0
Iotra|747.345|110.609|Outer Rim|Iotra|0
Ossus|699.508|319.002|Outer Rim|Auril|1
Murkhana|732.64|326.715|Outer Rim|Auril|1
Trogan|674.57|284.218|Outer Rim|Jospro|1
Jomark|681.559|266.747|Outer Rim|Jospro|1
Sy Myrth|700.107|250.897|Outer Rim|Jospro|0
Kile|709.091|234.398|Outer Rim|Jospro|0
Saleucami|733.126|168.177|Outer Rim|Suolriep|1
Boonta|745.663|149.337|Outer Rim|Suolriep|0
Komnor|743.716|198.07|Outer Rim|Suolriep|0
Kegan|861.737|89.57|Outer Rim|Calaron|0
Akrit'tar|890.476|67.159|Outer Rim|Calaron|0
Kubindi|869.118|27.378|Outer Rim|Calaron|1
Delacrix|853.139|85.765|Outer Rim|Calaron|0
Gestrex|862.563|52.26|Outer Rim|Calaron|0
Norval|863.086|44.055|Outer Rim|Calaron|0
Lowick|907.52|21.964|Outer Rim|Calaron|1
Droxu|894.145|-139.779|Outer Rim|Bheriz|0
Bheriz|915.23|-49.647|Outer Rim|Bheriz|0
Aduba|933.907|-114.941|Outer Rim|Bheriz|0
Nadiem|942.03|-183.507|Outer Rim|Baxel|0
|341.995|51.661|Inner Rim|Hapes Cluster|0
Glottal|926.929|-151.996|Outer Rim|Baxel|0
Teth|911.875|-210.191|Outer Rim|Baxel|1
Rinn|930.924|-210.909|Outer Rim|Baxel|1
Dilbana|912.021|-265.407|Outer Rim|Baxel|0
Rampa Minor|912.701|-228.942|Outer Rim|Baxel|0
Lirra|905.238|-213.622|Outer Rim|Baxel|0
Dubrava|891.217|-321.67|Outer Rim|Albanin|0
Clantaano|911.992|-272.051|Outer Rim|Albanin|0
Barab|904.776|-295.852|Outer Rim|Albanin|0
Daluuj|932.786|-314.26|Outer Rim|Albanin|0
Altor|924.406|-373.229|Outer Rim|Zoraster|0
Tammuz-an|875.679|-448.337|Outer Rim|Tammuz|0
Shiffrin|843.091|-509.582|Outer Rim|Tammuz|0
Shola|919.13|-421.025|Outer Rim|Tammuz|0
Lyran|790.95|-513.617|Outer Rim|Quiberon|0
R-Duba|849.919|-520.755|Outer Rim|Quiberon|0
Rothana|858.299|-555.826|Outer Rim|Quiberon|1
Arami|836.67|-383.335|Outer Rim|Galov|0
Gamorr|845.478|-431.556|Outer Rim|Galov|1
Hishyim|707.462|-509.892|Outer Rim|Abrion|0
Rishi|717.704|-520.755|Outer Rim|Abrion|1
Ukio|732.912|-533.48|Outer Rim|Abrion|1
Varristad|719.256|-542.791|Outer Rim|Abrion|0
Molavar|732.291|-558.309|Outer Rim|Abrion|1
Roon|704.048|-583.448|Outer Rim|Abrion|0
Kolanda Station|762.086|-445.544|Outer Rim|Yminis|0
Polus|147.685|354.399|Outer Rim|Oricho|0
Borgo Prime|172.957|373.137|Outer Rim|Oricho|0
Er'Kit|174.934|332.476|Outer Rim|Noonian|1
Pallaxides|213.349|293.227|Outer Rim|Noonian|0
Vinsoth|278.226|410.089|Outer Rim|Quelii|1
Cathar|284.579|374.828|Outer Rim|Quelii|0
Halmad|289.352|333.662|Outer Rim|Quelii|0
Dathomir|314.44|362.44|Outer Rim|Quelii|1
Drackmar|334.294|372.922|Outer Rim|Quelii|0
G'wenee|249.689|331.144|Outer Rim|Weneen|0
Wayland|274.605|243.244|Outer Rim|Ojoster|0
Taris|271.806|290.318|Outer Rim|Ojoster|1
Bandomeer|319.046|322.255|Outer Rim|Meerian|0
Gargon|322.013|288.042|Outer Rim|Mandalore|0
Phindar|422.287|301.766|Outer Rim|Demetras|1
Mandalore|363.452|272.211|Outer Rim|Mandalore|1
Harloen|328.417|330.832|Outer Rim|Belsmuth|0
Botajef|344.777|351.48|Outer Rim|Belsmuth|1
Kessel|836.339|-11.369|Outer Rim|Kessel|1
Honoghr|847.744|-29.564|Outer Rim|Kessel|0
Formos|893.654|-25.297|Outer Rim|Kessel|1
Zerm|826.724|-20.32|Outer Rim|Kessel|0
Rnda|814.709|-14.94|Outer Rim|Kessel|0
Aeneid|845.642|-19.703|Outer Rim|Kessel|0
Little Kessel|863.457|-21.07|Outer Rim|Kessel|0
Prishella|881.603|-24.124|Outer Rim|Kessel|0
Drualkiin|892.848|-2.391|Outer Rim|Kessel|0
Handooine|736.407|248.899|Outer Rim|Phelleem|0
Jabiim|755.185|227.579|Outer Rim|Phelleem|1
Syvris|848.677|-344.773|Outer Rim|Al-Nasrl|0
Unagin|840.975|-339.92|Outer Rim|Al-Nasrl|0
Koiogra|670.839|-616.968|Outer Rim|Grohl|0
Ord Grovner|338.752|-878.347|Outer Rim|Khuiumin|0
Florn|811.513|440.167|Outer Rim|Pakuuni|0
Pakuuni|851.873|386.329|Outer Rim|Pakuuni|0
Munto Codru|895.225|364.89|Outer Rim|Pakuuni|0
Reginard|897.06|357.502|Outer Rim|Pakuuni|0
Refnar|857.99|363.5|Outer Rim|Pakuuni|0
Turkana|875.717|375.847|Outer Rim|Pakuuni|0
Shaylin|868.308|378.846|Outer Rim|Pakuuni|0
Gbu|839.345|374.236|Outer Rim|Pakuuni|0
Stenos|624.548|407.517|Outer Rim|Spadja|0
Tandankin|671.799|395.954|Outer Rim|Spadja|0
Corvis Minor|251.86|493.159|Outer Rim|Ciutric|0
Ciutric|251.701|475.211|Outer Rim|Ciutric|0
Asation|-9.554|694.671|Outer Rim|Gree|0
Gree|5.622|709.425|Outer Rim|Gree|0
Lahag Erli|-155.071|-577.765|Expansion Regions|Cantons of Lahag|0
Montitia|-166.507|-555.37|Expansion Regions|Mintitian Grant|0
Har Binande|-117.587|-631.45|Expansion Regions|Har Worlds|0
Solibus|-51.513|-570.617|Expansion Regions|Chitarghar|0
Gholondreine|-37.377|-584.912|Expansion Regions|Chitarghar|0
Noe'ha'on|-82.803|-623.032|Expansion Regions|Piryn SHar|0
Natalon|-96.939|-627.638|Expansion Regions|Piryn SHar|0
Copperline|-32.77|-619.855|Expansion Regions|Vatha|0
New Balosar|-32.135|-600.16|Expansion Regions|Arc d'Stot|0
Llon Nebulae|-10.375|-554.099|Expansion Regions|Itopol|0
Quesaya|28.857|-536.468|Expansion Regions|Andirma|0
Pendari|-10.534|-614.773|Expansion Regions|Vensensor|0
Tar Mordren|-39.6|-650.192|Expansion Regions|Vensensor|0
Calonica|-43.412|-656.069|Expansion Regions|Vensensor|0
Vandelhelm|120.344|-584.912|Expansion Regions|Epsi Collective|0
Woostri|129.715|-615.408|Expansion Regions|Woostri|0
Daemen|134.004|-635.421|Expansion Regions|Woostri|0
Qat Chrystac|92.39|-656.069|Expansion Regions|Parnabe|0
Nkllon|58.558|-614.773|Expansion Regions|Alchenaut|0
Rainos CLuster|62.688|-569.664|Expansion Regions|Rocantor|0
Ord Vaug|83.336|-587.93|Expansion Regions|Rocantor|0
Epica|61.417|-536.786|Expansion Regions|Bes Ber Bikade|0
Roona|54.111|-547.904|Expansion Regions|Bes Ber Bikade|0
Borkyne|46.963|-556.322|Expansion Regions|Bes Ber Bikade|0
Kinyen|10.75|-593.966|Expansion Regions|Bes Ber Bikade|0
Tregillis|107.002|-548.381|Expansion Regions|Tregillis|0
Lohopa|157.511|-562.517|Expansion Regions|Boeus|0
Droecil|108.114|-525.668|Expansion Regions|Boeus|0
Derra|205.002|-519.315|Expansion Regions|Mikaster|0
Vernet|268.641|-479.289|Expansion Regions|Baroli|0
Baroli|233.433|-478.653|Expansion Regions|Baroli|0
Gacerian|232.639|-512.802|Expansion Regions|Baroli|0
Kira|252.334|-599.048|Expansion Regions|Kira|0
Lazerian|251.54|-596.507|Expansion Regions|Kira|0
Kerkoidia|284.306|-594.089|Expansion Regions|Kira|1
Arrgaw|221.997|-605.719|Expansion Regions|Kira|0
Pax|220.408|-620.967|Expansion Regions|Kira|0
Ropagi|252.175|-601.907|Expansion Regions|Kira|0
Jurzan|193.407|-590.313|Expansion Regions|Jurzan|0
Aguarl|268.376|-519.791|Expansion Regions|Mbandamonte|0
Cerenia|293.789|-579.989|Expansion Regions|Mbandamonte|0
Bimin Three|236.927|-567.6|Expansion Regions|Majoor|0
Ragith|230.891|-525.827|Expansion Regions|Majoor|0
Majoor|230.097|-542.504|Expansion Regions|Majoor|0
Ramordia|228.668|-556.481|Expansion Regions|Majoor|0
M'haeli|215.802|-577.765|Expansion Regions|Majoor|0
Cheku|338.527|-504.067|Expansion Regions|Brevost|0
Sika|346.574|-512.961|Expansion Regions|Brevost|0
Coonee|345.304|-519.95|Expansion Regions|Brevost|0
Krann|338.58|-542.822|Expansion Regions|Brevost|0
Momansi|333.656|-550.446|Expansion Regions|Brevost|0
Brevost|318.408|-566.647|Expansion Regions|Brevost|0
Vendaxa|320.173|-456.629|Expansion Regions|Zarracina|1
Selsor|334.503|-494.325|Expansion Regions|Zarracina|0
Pamorjal|281.629|-442.016|Expansion Regions|Immerian Outback|0
Glom Tho|-208.623|191.798|Expansion Regions|Vardoss|0
Hijo|-173.258|174.311|Expansion Regions|Hijoan Space|0
Belassar|-155.504|181.544|Expansion Regions|Sarla|0
Mondress|-189.204|209.656|Expansion Regions|Mandress|0
Muzara|-76.507|182.407|Expansion Regions|Trestis|0
Barenth|-59.706|191.77|Expansion Regions|Drannik|0
Myomar|-126.285|205.71|Expansion Regions|Deadalis|1
Dorin|-141.695|192.723|Expansion Regions|Deadalis|1
Yinchorr|33.038|178.672|Expansion Regions|Fellwe|0
Golden Nyss|43.642|190.138|Expansion Regions|Fellwe|0
Immalia|-6.651|168.519|Expansion Regions|Immalia|0
Mayvitch|7.64|166.959|Expansion Regions|Immalia|0
Nivek|349.186|-486.277|Expansion Regions|Citlik|0
Tynna|287.136|-404.955|Expansion Regions|Tynna|1
Allanteen|319.114|-409.403|Expansion Regions|Tynna|0
Rhommamool|279.512|-362.812|Expansion Regions|Merthian|0
Bovo Yagen|319.749|-372.13|Expansion Regions|Kailion|0
Tlactehon|305.348|-395.425|Expansion Regions|Kailion|0
Tarmidia|325.891|-395.849|Expansion Regions|Kailion|0
Ryvellia|388.153|-439.051|Expansion Regions|Treffani|0
Thaere|383.706|-476.324|Expansion Regions|Thaere|0
Cularin|409.542|-451.758|Expansion Regions|Thaere|0
Merren|359.563|-436.298|Expansion Regions|Chaykin|0
|341.699|50.063|Inner Rim|Hapes Cluster|0
Gamor|350.245|-441.381|Expansion Regions|Chaykin|0
Milagro|360.199|-450.911|Expansion Regions|Chaykin|1
Bacrana|382.435|-465.947|Expansion Regions|Brak|0
Hilo|390.059|-389.072|Expansion Regions|Hilo|0
Charra|407.425|-408.979|Expansion Regions|Charra|0
Sarko|303.789|-277.245|Expansion Regions|Venzeiia|0
Terrijo|323.023|-292.657|Expansion Regions|Venzeiia|0
Mek va Uil|387.63|-308.931|Expansion Regions|Surron|0
Surron|359.025|-329.645|Expansion Regions|Surron|0
Altier|349.822|-350.529|Expansion Regions|Altier|0
Iktotchon|346.01|-406.438|Expansion Regions|Narvath|1
Aridus|366.128|-420.838|Expansion Regions|Narvath|1
Parcellus Minor|327.708|-258.997|Expansion Regions|Parcelus|0
Mimban|370.862|-200.679|Expansion Regions|Circarpous|1
Gyndine|313.036|-223.488|Expansion Regions|Circarpous|0
Ishanna|363.587|-214.241|Expansion Regions|Circarpous|0
Fabrin|371.231|-235.818|Expansion Regions|Circarpous|0
Celegia|387.876|-66.493|Expansion Regions|Noori|0
Quas Killam|441.38|-3.49|Expansion Regions|Couronne|0
Umbara|407.537|-18.49|Expansion Regions|Ghost Nebula|1
Nazzri|424.64|69.668|Expansion Regions|Dona Laza|0
Valgauth|405.663|83|Expansion Regions|Nojic|0
Vena|401.3|58.32|Expansion Regions|Nojic|0
Belasco|386.027|-136.812|Expansion Regions|Belasco|0
Zirulast|408.41|-110.229|Expansion Regions|Belasco|0
Trammen|365.437|-160.608|Expansion Regions|Harron|0
Chanosant|354.587|-167.512|Expansion Regions|Harron|0
Tarhassan|370.862|-182.554|Expansion Regions|Harron|0
Reytha|333.75|-203.761|Expansion Regions|Harron|0
Prazhi|377.026|-265.532|Expansion Regions|Cyrillian Protectorate|0
Cyrillia|370.122|-292.657|Expansion Regions|Cyrillian Protectorate|0
Zaloriis|406.001|-222.995|Expansion Regions|Askarian|0
T'surr|441.879|-243.585|Expansion Regions|Nuon e Safyd|0
Yutan|417.714|-294.383|Expansion Regions|Ombakond|0
Dica|464.977|-122.715|Expansion Regions|Tolemses|0
Erai|438.427|-155.923|Expansion Regions|Hangshan|0
Artesia|468.018|-164.307|Expansion Regions|Hangshan|0
Ulda Frav|440.03|-173.307|Expansion Regions|Hangshan|0
Mordagon|489.224|-233.475|Expansion Regions|Authala|0
Emberlene|463.086|-256.408|Expansion Regions|Authala|0
Scardia|458.524|-261.956|Expansion Regions|Inra-su-Mar|0
Shili|70.273|189.645|Expansion Regions|Ehosiq|1
Jestan|121.071|206.66|Expansion Regions|Corpheli|0
Draria|147.949|211.345|Expansion Regions|Lostar|0
Adin|155.1|215.414|Expansion Regions|Lostar|0
Nessem|112.81|186.193|Expansion Regions|Lostar|0
Kidriff|120.701|192.481|Expansion Regions|Lostar|0
Jazbina|152.881|196.55|Expansion Regions|Lostar|0
Corsin|189.869|233.415|Expansion Regions|Greater Plooriod|1
Ploo|234.872|235.388|Expansion Regions|Ploo|0
Serroco|254.722|241.552|Expansion Regions|Ploo|0
Boordii|274.08|236.497|Expansion Regions|Sumitra|0
Aquaris|298.985|220.346|Expansion Regions|Sumitra|1
Thustra|303.177|227.743|Expansion Regions|Sumitra|1
Tierfon|333.508|208.263|Expansion Regions|Dentari|0
Jendorn|346.577|187.426|Expansion Regions|Farstey|0
Alpheridies|361.126|183.357|Expansion Regions|Farstey|0
Thisspias|351.139|174.11|Expansion Regions|Farstey|1
Cartao|376.908|141.19|Expansion Regions|Prackla|1
Von-Alai|383.196|149.821|Expansion Regions|Locris|0
Sermeria|372.839|109.75|Expansion Regions|Locris|0
Carcel|378.51|109.997|Expansion Regions|Locris|0
Pirin|389.484|111.6|Expansion Regions|Locris|0
Gizer|406.108|115.209|Expansion Regions|Locris|0
Donovia|394.169|99.27|Expansion Regions|Hali|0
Illoud|393.429|92.859|Expansion Regions|Hali|0
Attahox|474.429|-218.31|Expansion Regions|Hocatar|0
Sepan|426.098|-311.891|Expansion Regions|Sepan|0
Wann Tsir|427.331|-325.083|Expansion Regions|Sepan|0
Roxuli|-227.364|160.071|Expansion Regions|Freestanding Subsectors|0
Mendicat|-238.378|166.646|Expansion Regions|Freestanding Subsectors|0
Celdaru|-242.653|180.291|Expansion Regions|Freestanding Subsectors|0
Aruza|-223.846|-478.971|Expansion Regions|Freestanding Subsectors|0
Lequabis|-213.045|-471.347|Expansion Regions|Freestanding Subsectors|0
Kayri|-207.804|-514.391|Expansion Regions|Freestanding Subsectors|0
Taloraan|-242.27|-509.149|Expansion Regions|Freestanding Subsectors|0
Soun|-199.691|145.951|Expansion Regions|Freestanding Subsectors|0
Poviduze|-190.809|-489.454|Expansion Regions|Freestanding Subsectors|0
Selvaris|-209.389|65.597|Inner Rim||0
Reecee|-133.549|104.613|Inner Rim||0
Rondai|-127.631|172.782|Inner Rim||0
Bengat|-110.534|157.219|Inner Rim||0
Bilbringi|-121.384|161.274|Inner Rim||1
Walalla|-154.839|-395.851|Inner Rim|Seventh Security Zone|0
Donadus|-157.799|-382.659|Inner Rim|Bamula|0
Mindabaal|-160.018|-374.028|Inner Rim||0
K'taktaxka|-196.267|-467.239|Inner Rim||0
Shasfath|-185.786|-457.006|Inner Rim||0
Jandur|-128.085|-434.813|Inner Rim||0
Korbin|-108.727|-408.181|Inner Rim||0
Tasariq|-160.881|-417.305|Inner Rim||0
Neshtab|-91.848|152.452|Inner Rim||0
Aphran|-97.93|147.191|Inner Rim||0
Meastrinnar|-94.314|142.095|Inner Rim||0
Voltare|-93.82|135.683|Inner Rim||0
Carratos|-90.039|124.998|Inner Rim||0
Dulin|-42.025|-487.09|Inner Rim||0
Pa Tho|-55.957|-475.377|Inner Rim||0
Trevura|-68.287|-471.431|Inner Rim||0
Yn|-38.942|-421.127|Inner Rim||0
Fennesa|-42.518|-412.25|Inner Rim||0
Ord Lithone|9.29|162.778|Inner Rim||0
Datar|55.895|162.569|Inner Rim||0
Milvayne|50.047|153.369|Inner Rim||1
Barlok|45.608|132.532|Inner Rim|Marcol|0
Paqualis III|96.032|165.802|Inner Rim||0
Per Lupelo|87.648|154.336|Inner Rim||0
Drearia|79.387|142.499|Inner Rim||0
Champala|71.373|129.307|Inner Rim||1
Tomo-Reth|85.092|-405.807|Inner Rim||0
Norah|74.92|-421.712|Inner Rim||0
Mechis III|92.767|-466.284|Inner Rim||0
Renillis|89.438|-479.599|Inner Rim||0
Yag'Dhul|86.479|-489.864|Inner Rim|Givin Domain|1
Sukkult|90.548|-497.631|Inner Rim||0
Laertos|51.803|-476.455|Inner Rim||0
Tauber|74.273|-456.944|Inner Rim|Jaso|0
Thyferra|65.951|-442.241|Inner Rim|Jaso|0
Vanik|38.949|-411.263|Inner Rim||0
Kiffu|28.038|-431.329|Inner Rim|Kiffu|1
Janara|5.32|-458.485|Inner Rim||0
Pitrolea|6.184|-471.431|Inner Rim||0
Ketal|7.54|-482.651|Inner Rim||0
Wroona|97.298|-517.513|Inner Rim||0
Harrin|81.578|-502.162|Inner Rim|Harrin|0
Moorja|75.753|-515.478|Inner Rim||1
Calus|68.17|-525.835|Inner Rim||0
Ukatis|32.014|-515.571|Inner Rim||0
Shalam|187.023|205.01|Inner Rim||0
Bogden|105.91|177.988|Inner Rim||1
Omonoth|126.979|106.621|Inner Rim||0
Mindor|134.253|147.061|Inner Rim||0
Tala|209.474|60.043|Inner Rim||0
Mantessa|157.556|127.951|Inner Rim|Orus|0
Ejolus|153.364|188.365|Inner Rim||0
Poderis|179.626|117.594|Inner Rim|Orus|0
Hijarna|172.228|104.031|Inner Rim|Orus|0
Dagary Minor|193.928|182.94|Inner Rim||0
Joiol|185.894|101.008|Inner Rim|Orus|0
Vurdon Ka|169.022|94.414|Inner Rim|Darlonn|0
Adari|169.804|77.983|Inner Rim|Adari|0
Sochi|193.292|64.667|Inner Rim||0
Aleen|37.917|232.62|Mid Rim|Bright Jewel|1
Hillindor|164.381|-364.185|Inner Rim||0
Atzerri|189.4|-394.434|Inner Rim||1
Las Lagon|144.551|-391.474|Inner Rim||0
Affa|153.058|-391.937|Inner Rim||1
Foless|110.228|-381.838|Colonies||0
Kooriva|158.514|-424.394|Inner Rim||1
Heptalia|180.707|-452.598|Inner Rim||0
Borao|174.512|-460.088|Inner Rim||0
Vaklin|190.232|-472.387|Inner Rim||0
Roundtree|136.136|-466.653|Inner Rim||0
Arkam|140.112|-472.479|Inner Rim||0
Xeron|133.824|-479.784|Inner Rim||0
Beltrix III|115.145|-436.415|Inner Rim||0
Bestine|105.991|-410.801|Inner Rim||1
Myrkr|270.755|234.947|Inner Rim||0
Comkin V|212.208|216.997|Inner Rim|Nouane|0
Telerath|223.766|210.709|Inner Rim|Nouane|0
Kroctar|234.216|206.271|Inner Rim|Shataum|0
Nouane|203.298|193.543|Inner Rim|Nouane|1
Phateem|210.203|184.543|Inner Rim||0
Levian|258.443|192.77|Inner Rim||0
Carest|293.582|188.146|Inner Rim||0
Obroa-skai|291.64|175.016|Inner Rim||1
Asrat|271.944|156.706|Inner Rim||0
Filordis|238.839|146.997|Inner Rim|Larrin|0
Tirahnn|262.46|119.502|Inner Rim|Zeemacht Cluster|1
Relatta|224.27|113.214|Inner Rim||0
Berchest|209.844|127.455|Inner Rim|Anthos|0
Ktil|285.948|87.6|Inner Rim|Ktilac Regions|0
Colla IV|242.394|93.055|Inner Rim||1
Berri|224.362|66.331|Inner Rim||0
Kloper|207.031|37.029|Inner Rim||0
Korev VII|224.604|33.68|Inner Rim|Zaric|0
Vorsia|234.868|21.844|Inner Rim||0
Corvanni IV|231.539|16.203|Inner Rim|Neshig|0
Gelviddis Cluster|258.818|26.745|Inner Rim||0
Manress|291.738|26.375|Inner Rim||0
H'ratth|247.324|-13.901|Inner Rim||0
Pavo Prime|265.356|-15.381|Inner Rim||0
Telti|286.902|-6.966|Inner Rim||0
Dartessex IV|258.328|-45.526|Inner Rim||0
Mokk IX|285.7|-52.092|Inner Rim||0
Fadden|296.889|-131.617|Inner Rim||0
Antar|282.833|-210.402|Inner Rim||1
Ailon|258.791|-243.507|Inner Rim||0
Atapap I|255.554|-249.333|Inner Rim||0
Gendrah-Narvin|244.088|-303.891|Inner Rim||0
Iseno|220.323|-307.682|Inner Rim|Iseno|0
Denon|227.905|-316.559|Inner Rim||1
Perithal VI|243.533|-330.152|Inner Rim||0
Sagar|230.124|-335.608|Inner Rim||0
Spirana|257.126|-343.561|Inner Rim||0
Ronyards|230.864|-350.681|Inner Rim||0
Genon|249.451|-359.188|Inner Rim||0
Ord Vaxal|257.588|-376.943|Inner Rim|Callia|0
Chardaan|233.868|-399.16|Inner Rim||0
Babbadod|234.063|-406.085|Inner Rim||0
Itani|222.874|-415.239|Inner Rim||0
Shibric|235.173|-437.248|Inner Rim||0
Dargulli|206.044|-441.964|Inner Rim||0
Paonid|321.416|166.138|Inner Rim||0
Gravan Seven|339.54|160.682|Inner Rim||0
Korda Six|327.704|145.98|Inner Rim||0
Pengalan|332.738|133.465|Inner Rim||0
Dalcretti|313.227|117.375|Inner Rim||0
Taanab|353.359|110.162|Inner Rim||1
Hapes|350.642|53.377|Inner Rim|Hapes Cluster|0
Onderon & Dxun|370.615|17.405|Inner Rim|Japrael|1
Telkur Station|336.289|41.925|Inner Rim|Hapes Cluster|0
Chosper|339.499|41.113|Inner Rim|Hapes Cluster|0
|356.437|58.298|Inner Rim|Hapes Cluster|0
Andalia|334.631|46.14|Inner Rim|Hapes Cluster|0
Sennex|335.171|48.359|Inner Rim|Hapes Cluster|0
Daruvvia|336.247|50.582|Inner Rim|Hapes Cluster|0
Ket|336.565|52.222|Inner Rim|Hapes Cluster|0
Lovola|337.641|55.503|Inner Rim|Hapes Cluster|0
Maires|337.923|57.267|Inner Rim|Hapes Cluster|0
Vergill|338.487|58.166|Inner Rim|Hapes Cluster|0
Modus|339.951|58.872|Inner Rim|Hapes Cluster|0
Charubah|339.898|57.267|Inner Rim|Hapes Cluster|0
Cheruba|342.809|56.985|Inner Rim|Hapes Cluster|0
Relephon|344.273|55.979|Inner Rim|Hapes Cluster|0
Wodan|343.55|55.115|Inner Rim|Hapes Cluster|0
Divora|341.609|53.704|Inner Rim|Hapes Cluster|0
Algnadesh|343.338|54.286|Inner Rim|Hapes Cluster|0
Sargon|342.862|60.565|Inner Rim|Hapes Cluster|0
Febrini|347.695|59.93|Inner Rim|Hapes Cluster|0
Zadaria|348.453|58.854|Inner Rim|Hapes Cluster|0
Phelope|348.418|57.919|Inner Rim|Hapes Cluster|0
Jodaka|341.383|49.158|Inner Rim|Hapes Cluster|0
Stalsinek|341.736|46.971|Inner Rim|Hapes Cluster|0
Nantuker|344.092|44.87|Inner Rim|Hapes Cluster|0
k'Farri|347.496|42.348|Inner Rim|Hapes Cluster|0
Calfa|356.104|47.04|Inner Rim|Hapes Cluster|0
Dreena|358.468|49.333|Inner Rim|Hapes Cluster|0
Reboam|360.144|53.672|Inner Rim|Hapes Cluster|0
Shedu Maad|358.38|59.51|Inner Rim|Hapes Cluster|0
Terephon|355.857|60.78|Inner Rim|Hapes Cluster|0
Zalori|355.628|61.451|Inner Rim|Hapes Cluster|0
Orelon|351.351|64.62|Inner Rim|Hapes Cluster|0
Rynmar|353.594|62.461|Inner Rim|Hapes Cluster|0
Rainboh|356.007|63.534|Inner Rim|Hapes Cluster|0
Roqoo Depot|362.227|62.382|Inner Rim|Hapes Cluster|0
Talcharaim|345.801|51.708|Inner Rim|Hapes Cluster|0
Sivoria|345.575|52.695|Inner Rim|Hapes Cluster|0
Farnica|345.604|53.627|Inner Rim|Hapes Cluster|0
Novi|345.745|54.488|Inner Rim|Hapes Cluster|0
Gallinore|346.14|55.334|Inner Rim|Hapes Cluster|0
Baldavia|346.902|54.812|Inner Rim|Hapes Cluster|0
Theselon|347.763|54.586|Inner Rim|Hapes Cluster|0
Millinar|347.636|53.57|Inner Rim|Hapes Cluster|0
Lalmy'ash|347.805|52.667|Inner Rim|Hapes Cluster|0
Archais|348.242|51.976|Inner Rim|Hapes Cluster|0
Selab|349.343|51.609|Inner Rim|Hapes Cluster|0
Jovaria|350.811|51.355|Inner Rim|Hapes Cluster|0
Thrakia|351.714|50.762|Inner Rim|Hapes Cluster|0
Lemmi|351.742|51.778|Inner Rim|Hapes Cluster|0
Harterra|349.893|52.06|Inner Rim|Hapes Cluster|0
Ut|350.387|52.625|Inner Rim|Hapes Cluster|0
Arabanth|350.317|54.219|Inner Rim|Hapes Cluster|0
Carlania|350.049|55.236|Inner Rim|Hapes Cluster|0
Ediorung|349.442|56.195|Inner Rim|Hapes Cluster|0
Tumani|350.698|56.11|Inner Rim|Hapes Cluster|0
Tinta|351.657|55.687|Inner Rim|Hapes Cluster|0
Rbollea|352.165|55.264|Inner Rim|Hapes Cluster|0
Porus Vida|385.484|37.137|Inner Rim||0
|342.048|48.158|Inner Rim|Hapes Cluster|0
|342.672|46.359|Inner Rim|Hapes Cluster|0
|343.191|45.283|Inner Rim|Hapes Cluster|0
|343.946|43.914|Inner Rim|Hapes Cluster|0
|344.08|45.763|Inner Rim|Hapes Cluster|0
|345.004|44.197|Inner Rim|Hapes Cluster|0
|345.731|43.181|Inner Rim|Hapes Cluster|0
|346.832|42.948|Inner Rim|Hapes Cluster|0
|348.267|42.617|Inner Rim|Hapes Cluster|0
|348.954|43.376|Inner Rim|Hapes Cluster|0
|350.198|44.707|Inner Rim|Hapes Cluster|0
|351.759|45.536|Inner Rim|Hapes Cluster|0
|353.029|46.065|Inner Rim|Hapes Cluster|0
|355.005|46.551|Inner Rim|Hapes Cluster|0
|356.326|48|Inner Rim|Hapes Cluster|0
|357.278|48.84|Inner Rim|Hapes Cluster|0
|358.534|50.322|Inner Rim|Hapes Cluster|0
|358.492|51.317|Inner Rim|Hapes Cluster|0
|359.76|53.102|Inner Rim|Hapes Cluster|0
|359.749|54.329|Inner Rim|Hapes Cluster|0
|359.231|54.858|Inner Rim|Hapes Cluster|0
|358.744|55.356|Inner Rim|Hapes Cluster|0
|357.897|55.896|Inner Rim|Hapes Cluster|0
|357.463|56.52|Inner Rim|Hapes Cluster|0
|357.167|57.663|Inner Rim|Hapes Cluster|0
|356.903|60.489|Inner Rim|Hapes Cluster|0
|357.675|60.319|Inner Rim|Hapes Cluster|0
|358.437|60.531|Inner Rim|Hapes Cluster|0
|359.103|60.878|Inner Rim|Hapes Cluster|0
|354.711|61.919|Inner Rim|Hapes Cluster|0
|352.171|62.995|Inner Rim|Hapes Cluster|0
|356.537|63.224|Inner Rim|Hapes Cluster|0
|355.39|63.083|Inner Rim|Hapes Cluster|0
|354.773|62.977|Inner Rim|Hapes Cluster|0
|353.944|63.215|Inner Rim|Hapes Cluster|0
|353.212|63.939|Inner Rim|Hapes Cluster|0
|352.409|64.088|Inner Rim|Hapes Cluster|0
|348.978|56.834|Inner Rim|Hapes Cluster|0
|349.481|60.239|Inner Rim|Hapes Cluster|0
|348.652|59.868|Inner Rim|Hapes Cluster|0
|345.054|56.665|Inner Rim|Hapes Cluster|0
|345.957|57.145|Inner Rim|Hapes Cluster|0
|346.126|59.65|Inner Rim|Hapes Cluster|0
|345.145|59.748|Inner Rim|Hapes Cluster|0
|344.193|59.805|Inner Rim|Hapes Cluster|0
|347.17|59.156|Inner Rim|Hapes Cluster|0
|345.928|58.937|Inner Rim|Hapes Cluster|0
|345.653|60.729|Inner Rim|Hapes Cluster|0
|342.577|59.36|Inner Rim|Hapes Cluster|0
|342.64|50.439|Inner Rim|Hapes Cluster|0
|340.905|50.523|Inner Rim|Hapes Cluster|0
|340.481|51.497|Inner Rim|Hapes Cluster|0
|342.492|52.735|Inner Rim|Hapes Cluster|0
|342.884|53.529|Inner Rim|Hapes Cluster|0
|342.069|54.471|Inner Rim|Hapes Cluster|0
|342.757|54.841|Inner Rim|Hapes Cluster|0
|341.307|58.143|Inner Rim|Hapes Cluster|0
|338.513|56.503|Inner Rim|Hapes Cluster|0
|336.893|56.027|Inner Rim|Hapes Cluster|0
|337.433|53.614|Inner Rim|Hapes Cluster|0
|341.411|59.782|Inner Rim|Hapes Cluster|0
|338.827|59.738|Inner Rim|Hapes Cluster|0
|338.58|60.646|Inner Rim|Hapes Cluster|0
|339.735|60.831|Inner Rim|Hapes Cluster|0
|340.017|59.897|Inner Rim|Hapes Cluster|0
|341.12|61.096|Inner Rim|Hapes Cluster|0
|335.567|45.399|Inner Rim|Hapes Cluster|0
|336.498|44.729|Inner Rim|Hapes Cluster|0
|337.162|43.614|Inner Rim|Hapes Cluster|0
|337.726|42.676|Inner Rim|Hapes Cluster|0
|338.58|42.083|Inner Rim|Hapes Cluster|0
|338.474|41.145|Inner Rim|Hapes Cluster|0
|337.373|41.85|Inner Rim|Hapes Cluster|0
|335.073|42.528|Inner Rim|Hapes Cluster|0
|334.255|43.106|Inner Rim|Hapes Cluster|0
|336.209|43.586|Inner Rim|Hapes Cluster|0
|347.279|41.194|Inner Rim|Hapes Cluster|0
|347.364|44.341|Inner Rim|Hapes Cluster|0
|348.182|45.329|Inner Rim|Hapes Cluster|0
|350.059|42.873|Inner Rim|Hapes Cluster|0
|350.13|43.748|Inner Rim|Hapes Cluster|0
|351.16|44.129|Inner Rim|Hapes Cluster|0
|355.224|43.48|Inner Rim|Hapes Cluster|0
|353.77|44.976|Inner Rim|Hapes Cluster|0
|355.591|48.419|Inner Rim|Hapes Cluster|0
|356.466|49.491|Inner Rim|Hapes Cluster|0
|357.693|47.897|Inner Rim|Hapes Cluster|0
|359.245|50.437|Inner Rim|Hapes Cluster|0
|357.309|52.127|Inner Rim|Hapes Cluster|0
|357.933|52.889|Inner Rim|Hapes Cluster|0
|357.732|55.079|Inner Rim|Hapes Cluster|0
|356.6|56.646|Inner Rim|Hapes Cluster|0
|356.303|57.09|Inner Rim|Hapes Cluster|0
|355.996|57.535|Inner Rim|Hapes Cluster|0
|355.044|60.339|Inner Rim|Hapes Cluster|0
|353.887|61.285|Inner Rim|Hapes Cluster|0
|335.302|49.84|Inner Rim|Hapes Cluster|0
|349.673|60.332|Inner Rim|Hapes Cluster|0
|346.46|51.081|Inner Rim|Hapes Cluster|0
|347.349|50.837|Inner Rim|Hapes Cluster|0
Ambria|370.708|-14.22|Inner Rim|Airon|0
Taboon|368.951|-23.097|Inner Rim|Airon|0
Ithull|376.164|-24.392|Inner Rim|Airon|0
Merson|367.379|-36.505|Inner Rim|Airon|0
Virujansi|369.413|-52.503|Inner Rim||1
Zeltros|353.019|-69.569|Inner Rim||1
Mattri|347.933|-90.097|Inner Rim||0
Rasterous|306.691|-90.745|Inner Rim||0
Cona|326.942|-120.151|Inner Rim|Inner Cluster|0
Manaan|317.972|-144.193|Inner Rim||1
Truuine|305.026|-186.175|Inner Rim||0
Tal Nami|692.492|3.797|Hutt Space|Hutt Space|0
Alee|684.377|27.873|Hutt Space|Hutt Space|0
Keldooine|656.919|-84.046|Hutt Space|Hutt Space|0
Nar Bo Sholla|685.92|-93.735|Hutt Space|Hutt Space|0
Ilos|677.863|-26.352|Hutt Space|Hutt Space|0
Ilos Minor|691.515|-30.562|Hutt Space|Hutt Space|0
Kleeva|687.331|-187.311|Hutt Space|Hutt Space|0
Toydaria|671.357|-170.813|Hutt Space|Hutt Space|1
Tol Amn|636.659|-160.469|Hutt Space|Hutt Space|0
Runaway Prince|647.919|-139.389|Hutt Space|Hutt Space|0
Jilrua|651.261|-211.107|Hutt Space|Hutt Space|1
Ganath|686.526|-219.661|Hutt Space|Hutt Space|0
Ques|775.797|103.063|Hutt Space|Hutt Space|1
Terman|771.673|105.898|Hutt Space|Hutt Space|0
Cyborrea|735.978|18.605|Hutt Space|Hutt Space|0
Dirha|755.201|76.915|Hutt Space|Hutt Space|0
Kafane|778.9|49.55|Hutt Space|Hutt Space|0
Klatooine|774.4|96.254|Hutt Space|Hutt Space|1
Nimia|780.685|98|Hutt Space|Hutt Space|0
Vontor|775.541|96.157|Hutt Space|Hutt Space|0
Nar Kreeta|709.26|-35.558|Hutt Space|Hutt Space|0
Nimban|723.207|-33.631|Hutt Space|Hutt Space|0
Sionia|731.614|-17.183|Hutt Space|Hutt Space|0
Mulatan|759.099|-84.105|Hutt Space|Hutt Space|0
Langoona|780.311|-96.773|Hutt Space|Hutt Space|0
Zisia|797.703|-46.276|Hutt Space|Hutt Space|0
Ulmatra|796.197|-17.688|Hutt Space|Hutt Space|1
Sleheyron|769.783|-22.63|Hutt Space|Hutt Space|1
Kor Nasirii|741.377|-57.225|Hutt Space|Hutt Space|0
Kor Vosadii|738.37|-69.965|Hutt Space|Hutt Space|0
Kor Besadii|748.101|-71.115|Hutt Space|Hutt Space|0
Kor Hestilic|747.039|-80.758|Hutt Space|Hutt Space|0
Kor Nijiladii|755.267|-74.034|Hutt Space|Hutt Space|0
Nar Chunna|748.543|-96.416|Hutt Space|Hutt Space|0
Bootana Shagplan|787.292|-96.77|Hutt Space|Hutt Space|0
Du Hutta|713.125|-171.861|Hutt Space|Hutt Space|0
Hosko|743.633|-181.681|Hutt Space|Hutt Space|0
Varl|770.065|-155.661|Hutt Space|Hutt Space|0
Sakiya|772.553|-128.819|Hutt Space|Hutt Space|1
Gos Hutta|758.543|-117.428|Hutt Space|Hutt Space|0
Da Soocha|789.312|-142.305|Hutt Space|Hutt Space|0
Irith|704.541|-129.903|Hutt Space|Hutt Space|0
Kor Utoradii|739.077|-111.456|Hutt Space|Hutt Space|0
Kor Hunamma|745.093|-125.611|Hutt Space|Hutt Space|0
Kor Usilic|751.463|-112.694|Hutt Space|Hutt Space|0
Pybus|749.516|-137.908|Hutt Space|Hutt Space|0
Kor Oktanivii|752.524|-125.257|Hutt Space|Hutt Space|0
Kor Desilijic|765.529|-109.687|Hutt Space|Hutt Space|0
Huloon|770.395|-105.263|Hutt Space|Hutt Space|0
Kor Anjiliac|776.676|-101.901|Hutt Space|Hutt Space|0
Groth|771.545|-118.091|Hutt Space|Hutt Space|0
Kor Jiramma|777.914|-113.048|Hutt Space|Hutt Space|0
Kor Gejalli|777.914|-122.957|Hutt Space|Hutt Space|0
Kor Trinivii|786.761|-117.029|Hutt Space|Hutt Space|0
Sakidopa|779.772|-134.634|Hutt Space|Hutt Space|0
Sakiduba|774.199|-138.704|Hutt Space|Hutt Space|0
Nal Hutta & Nar Shaddaa|703.988|-205.807|Hutt Space|Hutt Space|1
Circumtore|708.697|-244.452|Hutt Space|Hutt Space|0
Carnovia|708.523|-291.239|Hutt Space|Hutt Space|0
Affavan|734.011|-259.116|Hutt Space|Hutt Space|0
Hollastin|759.325|-269.766|Hutt Space|Hutt Space|0
Aylayl|788.951|-289.467|Hutt Space|Hutt Space|0
Rorak|736.976|-228.396|Hutt Space|Hutt Space|0
Diyu|785.625|-217.689|Hutt Space|Hutt Space|0
Nar Kaaga|704.507|-331.043|Hutt Space|Hutt Space|0
Xolu|753.913|-327.377|Hutt Space|Hutt Space|0
Far Pando|764.039|-368.403|Hutt Space|Hutt Space|0
Near Pando|779.45|-411.86|Hutt Space|Hutt Space|0
Elgit|805.45|-77.427|Hutt Space|Hutt Space|0
Usk|830.197|-85.382|Hutt Space|Hutt Space|0
Moralan|833.143|-69.277|Hutt Space|Hutt Space|0
Tisht|849.416|-177.31|Hutt Space|Hutt Space|0
Nar Haaska|881.015|-149.028|Hutt Space|Hutt Space|0
Saqqar|850.463|-136.109|Hutt Space|Hutt Space|0
M'Hanna|815.024|-162.994|Hutt Space|Hutt Space|0
The Godsheart|830.037|-132.618|Hutt Space|Hutt Space|0
Sakifwanna|803.388|-118.083|Hutt Space|Hutt Space|0
Ylesia|845.229|-213.964|Hutt Space|Hutt Space|1
Riileb|831.548|-251.234|Hutt Space|Hutt Space|0
Poytta|855.999|-209.905|Hutt Space|Hutt Space|0
Ziugen|875.384|-217.288|Hutt Space|Hutt Space|0
Outland Transit|896.072|-215.586|Hutt Space|Hutt Space|0
Tsyk|806.583|-310.067|Hutt Space|Hutt Space|0
Cerea|-242.428|-664.301|Mid Rim|Semagi|1
Cheelit|-228.45|-678.913|Mid Rim|Semagi|0
Marzoon|-268.794|-634.123|Mid Rim|Marzoon|0
Bastooine|-224.638|-737.205|Mid Rim|Graador|0
Corbett CLuster|-238.457|-711.315|Mid Rim|Corbett|0
Koba|-195.572|-690.191|Mid Rim|Narrant|0
Riflor|-183.183|-698.291|Mid Rim|Narrant|0
Chalcedon|-211.455|-638.729|Mid Rim|Tashtor|0
Tashtor Seneca|-196.366|-633.487|Mid Rim|Tashtor|0
Iast|-155.388|-778.184|Mid Rim|Aldino|0
Halm|-170.953|-630.152|Mid Rim|Halm|0
Petabys Station|-186.519|-631.264|Mid Rim|Halm|0
Kaal|-73.217|-742.332|Mid Rim|Yushan|0
Abraxas|-46.374|-750.115|Mid Rim|Yushan|0
Dalisor|-76.076|-761.074|Mid Rim|Yushan|0
Rrulinn|-88.147|-768.857|Mid Rim|Yushan|0
Jiroch|-73.058|-780.928|Mid Rim|Yushan|0
Quamar|-72.899|-796.494|Mid Rim|Bruanii|0
Mugaar|-81.511|-809.884|Mid Rim|Bruanii|0
Cargamalis|-79.85|-808.016|Mid Rim|Bruanii|1
Lorta|-106.149|-777.866|Mid Rim|Gendius|0
Quaensan Prime|-103.29|-760.394|Mid Rim|Gendius|0
Porchello|-147.128|-765.954|Mid Rim|Elbaran|0
Elbara|-120.127|-732.758|Mid Rim|Elbaran|0
Hirsi|-127.115|-727.357|Mid Rim|Elbaran|0
Barcaria|-85.501|-669.383|Mid Rim|Sombure|0
Balis-Baurgh|-83.754|-677.643|Mid Rim|Sombure|0
Ichtor|-95.349|-689.396|Mid Rim|Sombure|0
D'rinba|-72.422|-705.96|Mid Rim|Sombure|0
Chibias|-67.34|-717.554|Mid Rim|Sombure|0
Miztoc|-14.607|-729.626|Mid Rim|Irnaj|0
Bomis Koori|-60.351|-687.535|Mid Rim|Wornal|0
Kriselist|-62.257|-697.859|Mid Rim|Wornal|0
Naalol|20.653|-707.707|Mid Rim|Spirva|1
Cyphar|9.059|-744.715|Mid Rim|Spirva|1
Feenix|-3.013|-738.838|Mid Rim|D'Aelgoth|0
Ogem|8.252|-772.356|Mid Rim|D'Aelgoth|1
Tarsa|1.144|-775.802|Mid Rim|D'Aelgoth|0
Selenius|11.154|-777.433|Mid Rim|D'Aelgoth|0
New Cylimba|32.025|-776.875|Mid Rim|D'Aelgoth|0
Dasoor|-5.954|-814.104|Mid Rim|Agarix|0
Mussubir|19.841|-780.843|Mid Rim|Senex|0
Skartis|24.586|-784.098|Mid Rim|Senex|0
Cyimarra|26.086|-780.821|Mid Rim|Senex|0
Veron|31.443|-782.325|Mid Rim|Senex|0
Presteen|31.717|-785.756|Mid Rim|Senex|0
Paramatan|26.146|-788.416|Mid Rim|Senex|0
Nantama|25.065|-792.23|Mid Rim|Senex|0
Rulaar|28.13|-790.973|Mid Rim|Senex|0
Aquella|29.651|-793.95|Mid Rim|Senex|0
Caltinia|33.157|-791.326|Mid Rim|Senex|0
Adoris|36.729|-792.693|Mid Rim|Senex|0
Knores|42.77|-791.833|Mid Rim|Senex|0
Nepoy|35.5|-795.852|Mid Rim|Senex|0
Nars|40.496|-796.778|Mid Rim|Senex|0
Neelanon|44.706|-796.461|Mid Rim|Senex|0
Senex|44.686|-790.851|Mid Rim|Senex|0
Crovna|47.486|-798.112|Mid Rim|Senex|0
Asmeru|48.853|-797.706|Mid Rim|Senex|1
Asmeru Anomaly|48.825|-797.803|Mid Rim|Senex|0
Karfeddion|38.44|-805.829|Mid Rim|Senex|0
Hutlar|37.811|-800.504|Mid Rim|Senex|0
Fengrine|42.485|-802.16|Mid Rim|Senex|0
Angratha|48.438|-802.187|Mid Rim|Senex|0
Hestria|48.174|-806.367|Mid Rim|Senex|0
Kedorzha|49.629|-810.6|Mid Rim|Senex|0
Simoom|45.898|-808.563|Mid Rim|Senex|0
Hovan|43.464|-811.923|Mid Rim|Senex|0
Serat|41.559|-810.362|Mid Rim|Senex|0
Yetoom|31.677|-815.769|Mid Rim|Senex|0
Tekurr'k|34.852|-811.469|Mid Rim|Senex|0
Port Evokk|36.329|-809.494|Mid Rim|Senex|0
Antiquity|32.956|-810.786|Mid Rim|Senex|0
Atron|37.414|-807.743|Mid Rim|Senex|0
Jalarren|34.04|-807.694|Mid Rim|Senex|0
Boro-borosa|38.732|-811.293|Mid Rim|Senex|0
Shoon|29.472|-810.212|Mid Rim|Senex|0
Osmani|28.127|-810.19|Mid Rim|Senex|0
Kamur|25.322|-813.308|Mid Rim|Senex|0
Voorsbain|34.856|-805.406|Mid Rim|Senex|0
Varadan|25.12|-811.033|Mid Rim|Senex|0
Suliana|30.451|-807.192|Mid Rim|Senex|0
Tranthellix|26.046|-809.225|Mid Rim|Senex|0
Usnia|24.699|-807.508|Mid Rim|Senex|0
Doreen|24.436|-805.542|Mid Rim|Senex|0
Bator Bai|26.641|-804.841|Mid Rim|Senex|0
Kalgo|25.305|-802.257|Mid Rim|Senex|0
Denebia|30.614|-803.245|Mid Rim|Senex|0
Anturus|36.047|-804.374|Mid Rim|Senex|0
Umthyg|-1.417|-813.927|Mid Rim|Juvex|0
Arporatal-Lanin|-1.836|-811.103|Mid Rim|Juvex|0
Farstone|-0.923|-816.039|Mid Rim|Juvex|0
Thull's Vault|-0.999|-808.087|Mid Rim|Juvex|0
Talhovi|-0.712|-806.036|Mid Rim|Juvex|0
Little Talhovi|-0.791|-801.962|Mid Rim|Juvex|0
Valorsi|3.594|-797.103|Mid Rim|Juvex|0
Carsanza|6.002|-798.565|Mid Rim|Juvex|0
Malador|10.177|-798.612|Mid Rim|Juvex|0
Yhifar|7.272|-788.76|Mid Rim|Juvex|0
Kardura|4.856|-789.986|Mid Rim|Juvex|0
Dioll|4.053|-792.491|Mid Rim|Juvex|0
Thermon|5.623|-793.32|Mid Rim|Juvex|0
Ossiathora|14.372|-789.466|Mid Rim|Juvex|0
Zaria|13.375|-795.128|Mid Rim|Juvex|0
Anstares|15.51|-793.84|Mid Rim|Juvex|0
Kassido|11.735|-787.799|Mid Rim|Juvex|0
Deminol|17.512|-791.777|Mid Rim|Juvex|0
Manforgon|15.412|-785.151|Mid Rim|Juvex|0
Velga|10.438|-812.689|Mid Rim|Juvex|0
Dramassia|4.327|-813.574|Mid Rim|Juvex|0
Q'mara|9.984|-815.633|Mid Rim|Juvex|0
Pieldi|6.666|-811.382|Mid Rim|Juvex|0
K'ath|1.609|-808.652|Mid Rim|Juvex|0
Pirralor|5.887|-807.093|Mid Rim|Juvex|0
Zyluria|4.231|-800.47|Mid Rim|Juvex|0
Resti Kel|8.496|-801.836|Mid Rim|Juvex|0
Tyluun|12.226|-804.083|Mid Rim|Juvex|0
Loovria|16.15|-809.463|Mid Rim|Juvex|1
Vulcar|14.695|-804.48|Mid Rim|Juvex|0
Tinallis|17.941|-806.676|Mid Rim|Juvex|0
Kimm Cresh|19.03|-804.661|Mid Rim|Juvex|0
Kimm Besh|19.572|-804.202|Mid Rim|Juvex|0
Kimm Aurek|20.048|-803.664|Mid Rim|Juvex|0
Juvex|23.025|-802.376|Mid Rim|Juvex|0
Eiattu|88.728|-753.928|Mid Rim|Ado|0
Medth|149.878|-728.038|Mid Rim|Ado|0
Indupar|142.254|-729.626|Mid Rim|Ado|0
Tshindral|152.102|-745.192|Mid Rim|Ado|0
StarForge Nebula|106.199|-745.668|Mid Rim|Ado|0
Echnos|93.997|-787.011|Mid Rim|Hadar|0
Rindao|45.66|-787.05|Mid Rim|Hadar|0
Parada|47.353|-782.923|Mid Rim|Hadar|0
Tibrin|71.583|-801.534|Mid Rim|Hadar|1
Opiteihr|185.457|-651.64|Mid Rim|Var Hagen|0
Vogel|167.191|-675.623|Mid Rim|Var Hagen|0
Alakatha|139.395|-659.263|Mid Rim|Var Hagen|0
Lanthe|142.89|-675.623|Mid Rim|Var Hagen|0
Vondarc|146.702|-692.936|Mid Rim|Var Hagen|0
Chryya|197.21|-729.944|Mid Rim|Dustig|0
Haruun Kal|179.58|-707.231|Mid Rim|Dustig|1
Kath|171.956|-707.231|Mid Rim|Dustig|0
Demos|222.147|-653.228|Mid Rim|Dustig|0
ZeHeth|212.299|-668.158|Mid Rim|Dustig|0
Malastare|208.329|-683.565|Mid Rim|Dustig|1
Nuvar|217.859|-711.837|Mid Rim|Dustig|0
Nuralee|244.066|-631.15|Mid Rim|Tyus|0
Tyus Cluster|208.646|-639.251|Mid Rim|Tyus|0
Umgul|259.949|-671.494|Mid Rim|Mulgard|0
Trevi|266.144|-722.32|Mid Rim|Quess|0
Old Mankoo|244.225|-702.784|Mid Rim|Quess|0
Karlinus|322.053|-692.936|Mid Rim|Chommel|0
Naboo|334.442|-707.231|Mid Rim|Chommel|1
Enarc|340.795|-716.125|Mid Rim|Alui|0
Alui|308.393|-727.403|Mid Rim|Alui|0
Ansion|-206.649|300.047|Mid Rim|Churnis|1
Namadii|-207.602|314.183|Mid Rim|Churnis|0
Gilatter|-219.673|288.77|Mid Rim|Churnis|0
Rustibar|-183.142|288.453|Mid Rim|Churnis|0
Kalaan|-197.596|272.569|Mid Rim|Churnis|0
Rago|-256.681|254.145|Mid Rim|Rago|0
Sinton|-235.398|275.587|Mid Rim|Rago|0
Kril'Dor|-239.527|250.492|Mid Rim|Outer Jalor|1
Ord Varee|-193.307|263.357|Mid Rim|Belshar|0
Glee Anselm|-180.283|239.215|Mid Rim|Jalor|1
Vaced|-164.558|221.108|Mid Rim|Jalor|0
Uba|-108.783|337.755|Mid Rim|Barsa|0
Dalron|-154.646|331.799|Mid Rim|Ariarch|0
Keitum|-163.581|319.291|Mid Rim|Ariarch|0
Iridonia|-115.454|293.56|Mid Rim|Clythe|1
Valrar|-118.79|273.547|Mid Rim|Clythe|0
Fornax|-100.207|263.422|Mid Rim|Clythe|0
Vortex|-91.505|221.147|Mid Rim|Clythe|0
Nentan|-69.711|232.211|Mid Rim|Clythe|0
Vicondor|-124.339|207.746|Mid Rim|Vorc|0
Ebra|68.473|332.633|Mid Rim|Kesh|0
Station 88|-119.783|209.488|Mid Rim|Vorc|0
Baltizaar|-62.087|277.24|Mid Rim|Corthenia|1
Orinda|-26.23|349.31|Mid Rim|Irishi|1
Obredaan|-13.008|320.959|Mid Rim|Irishi|0
Gonmore|-11.459|314.169|Mid Rim|Irishi|0
Ord Tessebok|-9.196|308.212|Mid Rim|Irishi|0
Dohu|-24.563|243.885|Mid Rim|Dohu|0
Ank Kit'aar|347.466|-589.854|Mid Rim|Druess|0
Sedesia|332.694|-608.119|Mid Rim|Druess|0
Kaliida Shoals|385.268|-731.691|Mid Rim|Ryndellian|0
Ryndellia|377.009|-706.119|Mid Rim|Ryndellian|1
Farstine|408.457|-708.184|Mid Rim|Ryndellian|0
Ninzan|412.587|-723.114|Mid Rim|Ryndellian|0
Andosha|494.703|-595.572|Mid Rim|Lambda|0
Argus|481.997|-615.743|Mid Rim|Lambda|0
Zolan|471.037|-627.815|Mid Rim|Lambda|1
Rintonne|455.313|-637.186|Mid Rim|Lambda|0
Ando|525.835|-597.637|Mid Rim|Lambda|1
Mon Gazza|516.146|-614.473|Mid Rim|Lambda|0
Triffis|383.521|-556.817|Mid Rim|Hevvrol|1
Bannistar Station|383.997|-572.7|Mid Rim|Hevvrol|0
Kalarba|404.01|-516.95|Mid Rim|Hevvrol|0
Kabray|469.29|-567.3|Mid Rim|Corweillian|0
Algara|482.156|-579.688|Mid Rim|Corweillian|0
Thape|530.917|-580.006|Mid Rim|Xan|0
Haseria|491.844|-518.856|Mid Rim|Haserian|0
Monastery|510.587|-496.301|Mid Rim|Haserian|0
Lelmra|444.83|-484.389|Mid Rim|Churba|0
New Cov|404.328|-495.984|Mid Rim|Churba|0
Lorahns|452.454|-424.986|Mid Rim|Sloo|0
Sanza|441.971|-452.623|Mid Rim|Sloo|0
Null|225.241|268.663|Mid Rim|Trans'Vulta|0
Skorrupon|225.837|252.343|Mid Rim|Trans'Vulta|0
Vulta|253.116|253.058|Mid Rim|Trans'Vulta|0
Geris|317.443|234.474|Mid Rim|Trans'Vulta|0
Surcaris|324.591|223.158|Mid Rim|Trans'Vulta|0
Djurmo|169.491|282.362|Mid Rim|Strabin|0
Lavisar|196.651|291.058|Mid Rim|Strabin|0
Lonnaw|-20.036|335.73|Mid Rim|Droma|0
Entuur|64.781|327.272|Mid Rim|Kesh|0
Ithor|110.882|321.673|Mid Rim|Ottega|1
Hewett|153.766|308.808|Mid Rim|Hewett|0
Ylix|101.947|268.187|Mid Rim|M'shinni|0
Genassa|111.835|295.943|Mid Rim|M'shinni|0
Urce|73.834|309.761|Mid Rim|Urce|0
Yout|0.811|277.597|Mid Rim|Qiilura|0
Qiilura|1.287|253.773|Mid Rim|Bright Jewel|0
Jarnollen|3.789|239.478|Mid Rim|Bright Jewel|0
Anobis|17.488|241.86|Mid Rim|Bright Jewel|0
Ord Mantell|4.742|254.964|Mid Rim|Bright Jewel|1
Korvaii|42.862|271.403|Mid Rim|Kordu|0
Walinor|113.979|221.252|Mid Rim|Shiwal|0
Triewahl|163.892|241.979|Mid Rim|Homon|0
Somov Rit|629.076|-534.739|Mid Rim|Onatos|0
Lahsbane|636.7|-548.557|Mid Rim|Onatos|0
Grakouine|642.576|-587.63|Mid Rim|Onatos|0
Leritor|578.249|-533.945|Mid Rim|Yucrales|0
Thoran|632.411|-465.329|Mid Rim|Manda|0
Zygia|650.2|-473.271|Mid Rim|Manda|0
Holess|666.242|-485.183|Mid Rim|Manda|0
Boranda|670.531|-491.219|Mid Rim|Manda|1
Manda|682.126|-504.243|Mid Rim|Manda|1
Dennaskar|699.597|-507.42|Mid Rim|Manda|0
Tarsunt|605.727|-416.885|Mid Rim|Bothan Space|0
Mandell|619.705|-407.832|Mid Rim|Bothan Space|0
Moonus|620.816|-404.655|Mid Rim|Bothan Space|0
Bothawui|622.213|-433.998|Mid Rim|Bothan Space|1
Krant|636.382|-446.905|Mid Rim|Bothan Space|0
Kothlis|624.311|-458.658|Mid Rim|Bothan Space|1
Nexus Ortai|547.912|-454.37|Mid Rim|Hertae|0
Masterra|537.429|-462.947|Mid Rim|Hertae|0
Hoylin|492.003|-371.777|Mid Rim|Fel Hu|0
Aikhibba|471.355|-394.331|Mid Rim|Fel Hu|0
Beris|501.374|-363.518|Mid Rim|Fel Hu|0
Centares|638.651|265.363|Mid Rim|Maldrood|1
The Wheel|628.962|251.862|Mid Rim|Maldrood|0
Abhean|619.909|238.52|Mid Rim|Maldrood|0
New Holstice|652.31|225.972|Mid Rim|Maldrood|0
Anzat|680.14|208.253|Mid Rim|Bryx|0
Bryx|634.998|193.253|Mid Rim|Bryx|0
Ingo|681.325|169.689|Mid Rim|Bortele|0
Ultaar|646.275|149.733|Mid Rim|Bortele|0
Zchtek|679.153|134.326|Mid Rim|Bortele|0
Pusat Station|697.101|121.937|Mid Rim|Bortele|0
Kalkovak|708.696|170.063|Mid Rim|Bortele|0
Peg Shar|692.177|110.978|Mid Rim|Halla|0
Bimmisaari|678.593|85.29|Mid Rim|Halla|0
Boz Pity|704.28|59.806|Mid Rim|Halla|1
Danuta|707.584|80.562|Mid Rim|Halla|0
Euceron|594.019|210.407|Mid Rim|Eucer|0
Talcene|578.136|194.047|Mid Rim|Talcene|0
Orleon|564.635|183.405|Mid Rim|Talcene|0
Metalorn|610.061|177.37|Mid Rim|Talcene|1
Gromas|544.781|271.24|Mid Rim|Perkell|1
Trancret|537.316|262.98|Mid Rim|Perkell|0
Aargonar|573.688|251.068|Mid Rim|Perkell|1
Concord Dawn|349.792|249.014|Outer Rim|Mandalore|1
Bseto|431.445|254.011|Mid Rim|Msst|0
Msst|405.119|231.02|Mid Rim|Msst|0
Garos|447.408|243.885|Mid Rim|Msst|1
Anteevy|459.678|263.898|Mid Rim|Esuain|1
Kromus|466.944|236.261|Mid Rim|Esuain|0
Kiva|390.824|207.671|Mid Rim|Venaarian|0
Venaari|376.886|188.969|Mid Rim|Venaarian|0
Katarr|386.654|169.313|Mid Rim|Vensori|0
Nixor|530.175|-240.546|Mid Rim|Eclorar|0
Farquar|510.036|-171.545|Mid Rim|Kurost|0
Sev Tok|507.495|-192.352|Mid Rim|Kurost|0
Nanth'ri|529.285|-207.285|Mid Rim|Kurost|0
Ruusan|491.294|-100.971|Mid Rim|Teraab|1
Pesmenben|504.159|-116.272|Mid Rim|Teraab|0
Drogheda|514.642|-118.336|Mid Rim|Teraab|0
Dohlban|679.743|-390.837|Mid Rim|Dohlbani|0
Void Station|653.194|-411.548|Mid Rim|Dohlbani|0
Rettna|569.122|-137.873|Mid Rim|Essaga|0
Daalang|567.039|-271.976|Mid Rim|Daalang|0
Kalinda|324.117|-622.097|Mid Rim|Vilonis|0
Alassa Major|337.142|-648.463|Mid Rim|Vilonis|0
Nigel|299.34|-608.755|Mid Rim|Vish|0
Roldalna|285.045|-606.213|Mid Rim|Vish|0
Seltos|285.362|-635.915|Mid Rim|Vish|0
Womrik|584.444|-557.77|Mid Rim|Dufilvian|0
Blenjeel|562.207|-570|Mid Rim|Dufilvian|0
Algarian|580.314|-594.142|Mid Rim|Dufilvian|0
Talay|592.068|-611.455|Mid Rim|Dufilvian|0
Ord Pardron|651.789|-599.86|Mid Rim|Dufilvian|0
Casfield|540.175|222.002|Mid Rim|Tennuutta|0
Ord Tiddell|554.628|220.255|Mid Rim|Tennuutta|0
Salvara|582.106|199.13|Mid Rim|Tennuutta|0
Romin|533.504|187.376|Mid Rim|Romintine|0
Low'n|519.685|181.817|Mid Rim|Romintine|0
Gavryn|513.967|166.093|Mid Rim|Romintine|0
Velmor|465.991|207.552|Mid Rim|Halori|0
Contruum|397.275|139.217|Mid Rim|Truum|1
Jeyell|514.126|146.556|Mid Rim|Roche|0
Roche|529.215|155.61|Mid Rim|Roche|0
Trasse|558.123|145.286|Mid Rim|Sarka|0
Sarka|588.301|151.004|Mid Rim|Sarka|0
Dulathia|454.436|147.514|Mid Rim|Lantillian|1
Lantillies|430.989|121.946|Mid Rim|Lantillian|1
Phaseera|453.52|106.222|Mid Rim|Lantillian|0
Uyter|452.871|71.904|Mid Rim|Lantillian|1
Avenelle|437.513|70.765|Mid Rim|Lantillian|0
New Apsolon|457.834|-40.456|Mid Rim|Terr'skiar|0
Coachelle|496.783|-34.579|Mid Rim|Terr'skiar|0
Terr'Skiar|479.454|-32.27|Mid Rim|Terr'skiar|0
Pizilis|479.03|-19.993|Mid Rim|Terr'skiar|0
Rorgam|499.139|-25.073|Mid Rim|Terr'skiar|0
Torn Station|457.467|-0.527|Mid Rim|Terr'skiar|0
Kashyyyk|472.517|11.164|Mid Rim|Mytaranor|1
Rakhuuun|489.746|4.024|Mid Rim|Mytaranor|0
Mytaranor|477.864|-10.101|Mid Rim|Mytaranor|0
Tholatin|475.247|-0.315|Mid Rim|Mytaranor|0
Kwookrrr|523.734|4.949|Mid Rim|Mytaranor|0
Ota|513.178|-35.902|Mid Rim|Mytaranor|0
Randon|526.463|-34.888|Mid Rim|Mytaranor|0
Messert|515.966|-24.121|Mid Rim|Mytaranor|0
Chamble|504.986|-13.015|Mid Rim|Mytaranor|0
Deysum|530.153|-58.306|Mid Rim|Trax|0
Lexrul|529.605|-75.052|Mid Rim|Trax|1
Uogo'cor|536.583|-90.343|Mid Rim|Trax|0
Bissillirus|502.737|-51.602|Mid Rim|Trax|0
Sneeve|559.144|-9.105|Mid Rim|Kastolar|1
Durkteel|579.32|-22.196|Mid Rim|Kastolar|1
Ubrikkia|595.574|-64.688|Mid Rim|Kastolar|0
Blimph|545|-45.288|Mid Rim|Kastolar|0
Yitabo|590.162|-29.531|Mid Rim|Kastolar|0
Chalacta|654.837|-20.713|Mid Rim|Kastolar|1
Kwenn|652.348|-82.837|Mid Rim|Kastolar|0
Chroma Zed|515.595|-284.316|Mid Rim|Maerdocia|0
Thokosia|545.847|-305.067|Mid Rim|Maerdocia|0
Shador|537.112|-314.756|Mid Rim|Maerdocia|0
Chokan|521.228|-330.163|Mid Rim|Maerdocia|0
Deneba|516.146|-344.14|Mid Rim|Maerdocia|0
Dractu|589.209|-339.057|Mid Rim|Lanic Space|0
Lannik|610.374|-330.513|Mid Rim|Lanic Space|1
Bresnia|555.377|-407.514|Mid Rim|Tandon|0
Spirador|568.243|-448.811|Mid Rim|Tandon|0
Nooli|568.878|-368.918|Mid Rim|Noolian|0
Dressel|579.52|-376.884|Mid Rim|Noolian|1
Torolis|595.721|-395.443|Mid Rim|Noolian|0
Iskalon|635.588|-627.815|Mid Rim|Trans-Nebular|0
Goroth|616.401|-647.932|Mid Rim|Trans-Nebular|0
Milarian|618.099|-646.851|Mid Rim|Trans-Nebular|0
Argovia|704.997|-477.559|Mid Rim|Endocray|0
Rearqu Cluster|483.264|134.887|Mid Rim|Taldot|0
Togoria|473.465|72.963|Mid Rim|Taldot|0
Balamak|561.584|43.076|Mid Rim|Taldot|1
Charros|613.486|71.459|Mid Rim|Taldot|0
Codia|-340.957|-520.631|Mid Rim|Freestanding Subsectors|0
Murgo|-258.746|233.338|Mid Rim|Freestanding Subsectors|0
Burska|-257.793|263.675|Mid Rim|Freestanding Subsectors|0
Ankus|-261.607|280.62|Mid Rim|Freestanding Subsectors|0
Naporar|-581.843|150.45|Unknown Regions|Chiss Ascendancy|0
The Red Twins|-250.275|293.842|Mid Rim|Freestanding Subsectors|0
Geroon|-298.613|172.187|Mid Rim|Freestanding Subsectors|0
Utegetu Nebula|-290.036|188.706|Mid Rim|Freestanding Subsectors|0
Herdessa|539.812|-637.98|Mid Rim|Herdessa|0
Habassa|534.57|-643.539|Mid Rim|Herdessa|0
Retep|530.758|-654.499|Mid Rim|Daimar|0
Radnor|554.424|-654.022|Mid Rim|Daimar|0
Ragna|578.09|-665.776|Mid Rim|Daimar|0
Monor|425.929|-540.139|Mid Rim|Doldur|0
Doldur|430.535|-524.574|Mid Rim|Doldur|0
Druckenwell|437.206|-533.945|Mid Rim|Doldur|0
Linuri|489.462|-546.016|Mid Rim|Doldur|0
Falleen|476.914|-554.434|Mid Rim|Doldur|1
Paqwepor Major|450.389|-555.069|Mid Rim|Paqwepori|0
Bogo Rai|-671.026|103.171|Unknown Regions||0
Celwis|-523.694|107.253|Unknown Regions||0
Klasse Ephemora|-560.524|62.274|Unknown Regions||0
Yashuvhu|-530.679|66.084|Unknown Regions||0
Zonama Sekot|-509.697|-350.583|Unknown Regions||0
Ilum|-413.014|245.642|Unknown Regions||1
Pesfavri|-423.394|188.747|Unknown Regions||0
Rakata Prime|-460.075|-185.671|Unknown Regions||1
The Redoubt|-322.354|210.386|Unknown Regions||0
Avidich|-610.083|120.375|Unknown Regions|Chiss Ascendancy|0
Ool|-620.173|115.789|Unknown Regions|Chiss Ascendancy|0
Shihon|-618.197|110.92|Unknown Regions|Chiss Ascendancy|0
Oyokal|-629.75|106.769|Unknown Regions|Chiss Ascendancy|0
Kinoss|-650.811|122.433|Unknown Regions|Chiss Ascendancy|0
Thearterra|-620.437|135.662|Unknown Regions|Chiss Ascendancy|0
Rhigar|-603.281|84.604|Unknown Regions|Chiss Ascendancy|0
Csilla|-592.921|122.131|Unknown Regions|Chiss Ascendancy|1
Jamiron|-587.435|133.639|Unknown Regions|Chiss Ascendancy|0
Rentor|-584.401|126.654|Unknown Regions|Chiss Ascendancy|0
Cioral|-589.975|115.648|Unknown Regions|Chiss Ascendancy|0
Cormit|-557.731|111.838|Unknown Regions|Chiss Ascendancy|0
Colonial Station Cam'co|-591.262|174.369|Unknown Regions|Chiss Ascendancy|0
Sposia|-591.897|142.09|Unknown Regions|Chiss Ascendancy|0
Ornfra|-556.761|152.673|Unknown Regions|Chiss Ascendancy|0
Schesa|-559.83|166.643|Unknown Regions|Chiss Ascendancy|0
Noris|-559.936|162.41|Unknown Regions|Chiss Ascendancy|0
Sharb|-550.093|158.811|Unknown Regions|Chiss Ascendancy|0
Csaus|-581.479|89.155|Unknown Regions|Chiss Ascendancy|0
Copero|-571.637|92.754|Unknown Regions|Chiss Ascendancy|0
Sarvchi|-566.239|98.045|Unknown Regions|Chiss Ascendancy|0
Colonial Station Chaf|-580.104|67.036|Unknown Regions|Chiss Ascendancy|0
Bakura|-438.157|-670.906|Outer Rim|Bakura|0
Red Nebula|-410.118|-1134.896|Wild Space||0
Mephout|-368.566|-1061.236|Wild Space||0
Seoul|-391.231|-1076.346|Wild Space||1
Nirauan|-219.708|403.902|Wild Space||0
Esfandia|-280.135|351.381|Wild Space||0
Needan|-230.762|-1081.871|Wild Space||0
Xerton|-143.763|664.844|Wild Space||0
Qonto|-121.053|664.182|Wild Space||0
Huk|-185.611|560.403|Wild Space||0
Kalee|-162.247|565.841|Wild Space||1
Guiteica|-176.395|584.146|Wild Space||0
Tovarskl|-165.541|552.363|Wild Space||0
Parshoone|-180.075|530.914|Wild Space||0
Alashan|-144.146|422.049|Wild Space||0
Marquarra|-151.436|470.275|Wild Space||0
Adumar|-194.013|352.511|Wild Space||0
Aeten|-169.164|386.96|Wild Space||0
Anoth|-173.689|-1097.811|Wild Space||0
Zonju|-129.928|-1153.055|Wild Space||0
Kinooine|-192.622|-1144.365|Wild Space||0
Zeta|-75.418|739.073|Wild Space||0
Shiva|28.098|-1121.778|Wild Space||0
Kesh|970.992|-33.29|Wild Space||0
Gorsh|325.24|669.48|Wild Space||0
Farana|752.926|626.085|Wild Space|Farana|0
Hull's Star|748.093|633.324|Wild Space|Farana|0
Trian|683.773|629.708|Wild Space|Trianii|0
Pypin|691.441|631.118|Wild Space|Trianii|0
Ekibo|684.597|628.424|Wild Space|Trianii|0
Brochiib|710.452|635.058|Wild Space|Trianii|0
Silken|353.882|-1008.234|Wild Space||0
Gulma|406.845|676.257|Wild Space||0
Morellia|764.98|650.933|Wild Space||1
Mytus|733.426|668.722|Wild Space||0
Velabri|713.876|-848.147|Wild Space||0
Lamaredd|751.119|-838.836|Wild Space||0
Naos|770.341|-809.404|Wild Space||0
Parthovian Cluster|830.419|587.4|Wild Space||0
Cholganna|800.678|467.583|Outer Rim|Colundra|1
Drongar|866.209|435.768|Wild Space||0
Hast|927.011|380.504|Wild Space||0
Zigoola|938.776|362.706|Wild Space||0
Targon|962.691|212.014|Wild Space||0
Pluthan|968.585|161.284|Wild Space||0
Smarteel|950.166|-478.752|Wild Space||0
Malagarr|1005.095|162.295|Wild Space||0
Takodana|-193.124|-632.573|Mid Rim|Tashtor|1
Jakku|-275.511|-316.755|Inner Rim||1
D'Qar|337.759|-785.103|Outer Rim|Sanbra|1
Hosnian Prime|149.768|-277.35|Core||1
Kamino|710.488|-530.778|Outer Rim|Abrion|1
Lola Sayu|637.665|358.748|Outer Rim|Belderone|1
Malachor|720.114|524.503|Outer Rim|Chorlian|1
Azzameen Station|215.322|-784.895|Outer Rim|Garis|0
Makeb|561.21|-321.197|Mid Rim|Aida|0
Florrum|660.291|439.837|Outer Rim|Sertar|1
Jedha|-335.869|-6.848|Mid Rim|Freestanding Subsectors|1
Scarif|740.025|-544.01|Outer Rim|Abrion|1
Lothal|934.763|286.534|Outer Rim|Dominus|1
Mortis|-55.975|733.387|Wild Space||1
Jelucan|515.985|558.55|Outer Rim|Kwymar|1
Abafar|285.056|439.617|Outer Rim|Sprizen|1
Balnab|8.384|228.279|Mid Rim|Bright Jewel|1
Bardotta|-118.899|-345.621|Colonies||1
Andelm IV|330.541|-973.767|Outer Rim|Svivreni|1
Gorse|358.316|-80.167|Inner Rim||1
Kiros|73.389|179.243|Expansion Regions|Ehosiq|1
Zakuul|-744.352|-345.692|Unknown Regions||0
Garel|912.27|244.527|Outer Rim|Dominus|1
The Maw|829.763|-9.561|Outer Rim|Kessel|1
Indobok|410.109|-555.98|Mid Rim|Hevvrol|0
Orax|15.022|-1068.917|Outer Rim|Subterrel|0
Eadu|903.274|-37.139|Outer Rim|Kessel|1
Ring of Kafrene|-140.118|-515.468|Expansion Regions|Thand|1
Wobani|669.273|190.865|Mid Rim|Bryx|1
Lasan|443.613|-1028.573|Wild Space||1
Lah'mu|19.345|596.411|Outer Rim|Raioballo|1
Trandosha|473.695|13.126|Mid Rim|Mytaranor|1
Voss|746.931|362.631|Outer Rim|Allied Tion|1
Poln System|-114.362|446.382|Outer Rim|Prefsbelt|0
Atollon|928.219|280.625|Outer Rim|Dominus|1
Oovo|776.331|175.003|Outer Rim|Tharin|1
Quesh|781.565|-55.599|Hutt Space|Hutt Space|0
Peragus II|581.16|593.31|Outer Rim|Xappyh|0
Dosuun|-368.167|-1019.857|Wild Space||0
Yalara|-273.049|-1174.904|Wild Space||0
Raydonia|379.202|336.366|Outer Rim|Belsmuth|1
Aaeton|-54.005|14.372|Core||0
Crakull|-478.442|-66.017|Unknown Regions||0
Darada|-26.038|25.026|Core||0
Eliad|186.687|-1073.861|Outer Rim|Minos|0
Eshan|237.663|175.856|Inner Rim||0
Genian|483.021|-63.063|Mid Rim|Trax|0
Kalevala|351.082|284.794|Outer Rim|Mandalore|1
Karra|-157.043|-917.722|Outer Rim|Rayter|0
Kodai|626.302|368.385|Outer Rim|Belderone|0
Lenico IV|62.809|386.906|Outer Rim|Cademimu|0
Nim Drovis|622.668|294.619|Outer Rim|Meridian|0
Odacer-Faustin|564.865|483.091|Outer Rim|Esstran|0
Ord Ibanna|136.716|-781.355|Outer Rim|Brema|0
Ord Sigatt|212.334|315.442|Outer Rim|Noonian|0
Ordo|356.867|267.676|Outer Rim|Mandalore|0
Osadia|-60.099|-16.946|Core||0
Panatha|-388.465|-626.018|Outer Rim|Pacanth Reach|0
Quelii|317.67|372.077|Outer Rim|Quelii|0
Rekkiad|737.229|540.97|Outer Rim|Chorlian|0
Sorjus|609.912|294.792|Outer Rim|Meridian|0
Taral V|911.978|290.647|Outer Rim|Calamari|0
Vanquo|323.235|311.108|Outer Rim|Meerian|0
Ringo Vinda|609.018|215.224|Mid Rim|Eucer|1
Bpfassh|138.399|-925.996|Outer Rim|Sluis|0
Sarrish|-17.079|-613.832|Expansion Regions|Vensensor|1
Uphrades|171.34|175.131|Inner Rim||0
Denova|283.797|266.483|Outer Rim|Ojoster|0
Kaon|773.665|393.386|Outer Rim|Tion Hegemony|0
Oricon|446.339|634.704|Outer Rim|Corva|0
Nathema|734.736|513.701|Outer Rim|Chorlian|0
Utrost|14.195|4.175|Core||0
Phaegon_III|214.776|-738.459|Outer Rim|Grumani|0
Jagomir|579.813|464.877|Outer Rim|Esstran|0
Fwillsving|848.966|-1.514|Outer Rim|Calaron|0
Kirtania|442.97|519.558|Outer Rim|Nembus|0
Transel|58.777|-387.26|Colonies||0
Malrev IV|433.752|332.386|Outer Rim|Thrasybule|0
Carlac|-91.509|413.975|Outer Rim|Prefsbelt|0
Kadavo|789.335|556.938|Wild Space||1
Orondia|722.483|-180.722|Hutt Space|Hutt Space|1
Patitite Pattuna|23.876|224.665|Mid Rim|Bright Jewel|1
Quarzite|189.691|-370.86|Inner Rim||1
Stobar|140.302|-530.096|Expansion Regions|Boeus|1
Zanbar|373.4|287.645|Outer Rim|Mandalore|1
Zardossa Stix|-145.978|-314.636|Colonies||1
Cybloc|643.249|295.6|Outer Rim|Meridian|0
Taul|-110.947|-878.579|Outer Rim|Kriz|1
Noe'ha'on|-75.985|-623.321|Expansion Regions|Piryn SHar|1
Ahch-To|-651.605|-371.236|Unknown Regions||1
Cantonica|737.407|585.696|Outer Rim|Corporate Sector|1
Crait|248.05|-744.476|Outer Rim|Grumani|1
Trantor|146.12|-64.355|Core||0
Salient|752.63|614.099|Outer Rim|Corporate Sector|1
Ganthel|75.948|27.57|Core||1
Quell|586.648|323.269|Outer Rim|Nuiri|1
Seelos|509.133|545.761|Outer Rim|Kwymar|1
Stygeon Prime|572.269|289.747|Outer Rim|Nuiri|1
Lotho Minor|-210.993|-792.941|Outer Rim|Wazta|1
Savareen|591.877|-688.263|Outer Rim|Savareen|1
Vandor|427.165|-443.769|Mid Rim|Sloo|1
Crustai|-387.053|125.905|Unknown Regions||0
Telaris|849.259|354.859|Outer Rim|Pakuuni|1
Teya IV|138.666|216.79|Expansion Regions|Lostar|0
Orto Plutonia|431.578|-968.659|Outer Rim|Sujimis|1
Apatros|563.024|-685.06|Outer Rim|Savareen|0
Chad|671.009|263.914|Outer Rim|Jospro|1
Drurish|185.277|-58.825|Core|Kuat|0
Vodran|773.218|71.262|Hutt Space|Hutt Space|1
Orto|146.339|-910.468|Outer Rim|Sluis|1
Plympto|144.717|-187.766|Core|Corellian|1
Laboi II|730.602|132.707|Outer Rim|Suolriep|0
Widek|-77.56|-4.912|Core|Farlax|0
Bedlam|356.622|224.747|Mid Rim|Thursa|0
Dweem|869.579|10.169|Outer Rim|Calaron|0
Doan|116.856|353.335|Outer Rim|Halthor|0
Krownest|328.188|264.487|Outer Rim|Mandalore|1
Katraasii|360.22|321.285|Outer Rim|Belsmuth|0
Altyr V|346.673|487.02|Outer Rim|Morshdine|0
Chrellis|181.22|425.989|Outer Rim|Lahara|0
Keeper's World|318.98|483.316|Outer Rim|Sprizen|0
Tholoth|223.73|-234.721|Colonies||1
Oba Diah|884.828|-14.437|Outer Rim|Kessel|1
Yanibar|642.725|-917.056|Wild Space||0
Uvena Prime|174.147|-810.728|Outer Rim|Seswenna|0
Kaikielius|1.471|-10.018|Core||0
Argul|16.852|-775.336|Mid Rim|D'Aelgoth|0
Diab|-189.276|384.362|Wild Space||0
Exegol|-597.906|237.279|Unknown Regions||1
Batuu|-387.826|-555.59|Outer Rim|Trilon|1
Pasaana|400.369|-298.679|Expansion Regions|Ombakond|1
Sinta|556.005|-183.709|Mid Rim|Hune|1
Kijimi|649.226|169.863|Mid Rim|Bryx|1
Ajan Kloss|56.074|401.682|Outer Rim|Cademimu|1
]==]

GAR_DP.hyperlanesRaw = {
    { name = "Rimma Trade Route", planets = { "Abregado-rae", "Dentaal", "Giju", "Ghorman", "Vanik", "Thyferra", "Tauber", "Yag'Dhul", "Sukkult", "Wroona", "Tregillis", "Vandelhelm", "Woostri", "Daemen", "Alakatha", "Lanthe", "Vondarc", "Medth", "Tshindral", "Sullust", "Eriadu", "Bith", "Triton", "Praesitlyn", "Sluis Van", "Denab", "Tarabba", "Adarlon", "Karideph", "Pergitor", "Kal'Shebbol", } },
    { name = "Corellinan Run", planets = { "Coruscant", "Ixtlar", "Wukkar", "Kailor V", "Xorth", "Vuma", "Leria Kerlsil", "Perma", "Lolnar", "Rehemsa", "Sedratis", "Rydonni Prime", "Corellia", "Tinnel", "Loronar", "Byblos", "Pencael", "Havricus", "Iseno", "Denon", "Perithal VI", "Spirana", "Rhommamool", "Tlactehon", "Allanteen", "Gamor", "Milagro", "Thaere", "New Cov", "Druckenwell", "Mon Gazza", "Herdessa", "Radnor", "Christophsis", "Savareen", "Ryloth", "Smuggler's Run", } },
    { name = "Corellian Trade Spine", planets = { "Corellia", "Chasin", "Condular", "Hosnian Prime", "Gandeal", "Belazura", "Bryexx", "Enisca", "Kelada", "Foless", "Bestine", "Mechis III", "Renillis", "Yag'Dhul", "Harrin", "Moorja", "Calus", "Epica", "Roona", "Borkyne", "Kinyen", "Pendari", "Tar Mordren", "Calonica", "Bomis Koori", "Kriselist", "Chibias", "Kaal", "Dalisor", "Jiroch", "Quamar", "Cargamalis", "Mugaar", "Aztubek", "Kumru", "High Chunah", "Kirtarkin", "Mexeluine", "Gerrenthum", "Indellian", "Bendeluum", "Zhanox", "Ione", "Mataou", "Anantapar", "Shuxl", "Ertegas", "Darlyn Boda", "Orn Kios", "Ozu", "Isde Naha", "Togominda", "Berrol's Donn", "Sil'Lume", "Manpha", "Terminus", } },
    { name = "Hydian Way", planets = { "Bonadan", "D'ian", "Lythos", "Mall'ordian", "Reltooine", "Cadomai", "Ruuria", "Listehol", "Tantive", "Doniphon", "Telos", "Praadost", "Pho Ph'eah", "Toprawa", "Simpla", "Hynah", "Sorrus", "Junction", "Celanon", "Hijado", "Botajef", "Harloen", "Bandomeer", "Skorrupon", "Corsin", "Adin", "Draria", "Kidriff", "Nessem", "Bogden", "Paqualis III", "Per Lupelo", "Drearia", "Champala", "Nierport", "Uviuy Exen", "Wakeelmui", "Brentaal", "Skako", "Aldraig", "Demophon", "Glithnos", "Fedalle", "Trantor", "Talravin", "Sarapin", "Trellen", "Mawan", "Loretto", "Baraboo", "Bellassa", "Jaciprus", "Voktunma", "Exodeen", "Boudolayz", "Herzob", "Besnia", "Koensayr", "Aquilae", "Denon", "Sagar", "Ronyards", "Chardaan", "Babbadod", "Shibric", "Baroli", "Gacerian", "Ragith", "Majoor", "Ramordia", "Arrgaw", "Pax", "ZeHeth", "Malastare", "Chryya", "Darkknell", "Cmaoli Di", "Eriadu", "Averam", "Shumavar", "Atravis", "Tosste", "Rutan", "Fwatna", "Terminus", "Imynusoph", } },
    { name = "Perlemian Trade Route", planets = { "Coruscant", "Alsakan", "Grizmallt", "Anaxes", "Corulag", "Chandrila", "Brentaal", "Esseles", "Rhinnal", "Ralltiir", "Delle", "Yabol Opa", "Ifmix", "Shulstine", "Castell", "Raithal", "Vurdon Ka", "Joiol", "Chazwa", "Relatta", "Tirahnn", "Dalcretti", "Taanab", "Sermeria", "Carcel", "Pirin", "Gizer", "Lantillies", "Rearqu Cluster", "Jeyell", "Roche", "Orleon", "Talcene", "Salvara", "Euceron", "Abhean", "The Wheel", "Centares", "Antemeridias", "Budpock", "Columex", "Arcan", "Lianna", "Thanium", "Felucia", "Mossak", "Galidraan", "Arcan", "Lianna", "Barseg", "Desevro", "Livien", "Kanaver", "Janodral Mizar", "Makem Te", "Quermia", } },
    { name = "Elgit-M'Hanna Corridor", planets = { "Elgit", "Sakifwanna", "M'Hanna", } },
    { name = "Reena Trade Route", planets = { "Druckenwell", "Haseria", "Monastery", "Masterra", "Nexus Ortai", "Spirador", "Bothawui", } },
    { name = "Bothan Run", planets = { "Bothawui", "Moonus", "Mandell", "Lannik", "Daalang", } },
    { name = "Guu Run", planets = { "Kitel Phard", "Dahrtag", "Illodia", "Giju", } },
    { name = "Shipwrights' Trace", planets = { "Abregado-rae", "Fondor", "Thyferra", "Teyr Vulvarch", "Atzerri", "Chardaan", "Tynna", "Allanteen", } },
    { name = "Harrin Trade Corridor", planets = { "Harrin", "Wroona", "Droecil", "Lohopa", "Jurzan", "Arrgaw", "Kira", "Cerenia", "Brevost", "Momansi", "Krann", "Coonee", "Sika", "Milagro", "Merren", } },
    { name = "Enarc Run", planets = { "Kira", "Roldalna", "Nigel", "Kalinda", "Alassa Major", "Naboo", "Enarc", } },
    { name = "Shiritoku Way", planets = { "Bakura", "Timora", "Ast Kikorie", "Sanyassa", "Endor", } },
    { name = "Spar Trade Route", planets = { "Endor", "Trindello", "Qina", "Vex", "Firrerre", "Houche", "Vasha", "Maya Kovel", "Thonner", "Ovise", "Annaj", "Abbaji", "Cerea", } },
    { name = "Great Gran Run", planets = { "Cerea", "Chalcedon", "Tashtor Seneca", "Takodana", "Petabys Station", "Halm", "Har Binande", "Natalon", "Noe'ha'on", "Kinyen", } },
    { name = "Cerean Reach", planets = { "Cerea", "Cheelit", "Koba", "Riflor", "Hirsi", "Elbara", "Quaensan Prime", "Lorta", "Shuldene", "Lutrillia", "Mijos", "Gerrenthum", } },
    { name = "Koda Spur", planets = { "Koda Station", "Ryoone", "Lutrillia", "Mijos", "Gerrenthum", "Council", "Nothoiin", "Saila Na", "Bavva", "Dolla", } },
    { name = "Lipsec Run", planets = { "Lipsec", "Virgillia", "Sump", "Keskin", "Abridon", "Isde Naha", "Bettel", "Mev", "Kelrodo-Ai", "Dorvalla", "Eriadu", } },
    { name = "Namadii Corridor", planets = { "Coruscant", "Tanjay", "Weerden", "Galvoni", "Twith", "Pantolomin", "Borleias", "Ord Mirit", "Palanhi", "Carratos", "Voltare", "Meastrinnar", "Aphran", "Bengat", "Bilbringi", "Rondai", "Dorin", "Vaced", "Glee Anselm", "Ord Varee", "Kalaan", "Ansion", "Namadii", } },
    { name = "Veragi Trade Route", planets = { "Vinsoth", "Salin", "Ciutric", "Corvis Minor", "Argazda", "Bimmiel", "Birgis", "Seline", "Sernpidal", "Veragi", "Trassitan", "Dubrillion", "Ahakista", "Dantooine", "Sinsang", "Anx Minor", "Ord Trasi", } },
    { name = "Triellus Trade Route", planets = { "Centares", "Sy Myrth", "Handooine", "Jabiim", "Taskeed", "Dennogra", "Junkfort Station", "Nimat", "Tammar", "Kegan", "Gestrex", "Norval", "Kubindi", "Drualkiin", "Formos", "Eadu", "Bheriz", "Aduba", "Glottal", "Teth", "Rampa Minor", "Dilbana", "Clantaano", "Barab", "Dubrava", "Syvris", "Arami", "Gamorr", "Lyran", "Molavar", "Koiogra", "Piroket", "A-Foroon", "B-Foroon", "C-Foroon", "Ooo-temiuk", "Tatooine", "Andooweel", "Kemal Station", "New Ator", "Issor", "Arkanis", } },
    { name = "D'aelgoth Trade Route", planets = { "Kriselist", "Miztoc", "Feenix", "Cyphar", "Ogem", "Selenius", "Kassido", "Ossiathora", "Deminol", "Anstares", "Zaria", "Malador", "Resti Kel", "Pirralor", "Pieldi", "Velga", "Loovria", "Tinallis", "Kimm Cresh", "Kimm Besh", "Kimm Aurek", "Juvex", "Kalgo", "Denebia", "Anturus", "Karfeddion", "Atron", "Port Evokk", "Tekurr'k", "Yetoom", "Dolla", } },
    { name = "Byss Run", planets = { "Coruscant", "Foerost", "Ruan", "Jerrilek", "Empress Teta", "Keeara Major", "Prakith", "Byss", } },
    { name = "Salin Corridor", planets = { "Botajef", "Phindar", "Gala", "Vjun", "Lucazec", "Columex", } },
    { name = "Pabol Sleheyron", planets = { "Randon", "Yitabo", "Chalacta", "Ilos", "Ilos Minor", "Nar Kreeta", "Nimban", "Sleheyron", "Ulmatra", "Zerm", "Aeneid", "Little Kessel", "Honoghr", "Little Kessel", "Prishella", "Formos", } },
    { name = "Kessel Run", planets = { "Zerm", "Kessel", "Formos", } },
    { name = "Randon Run", planets = { "Lantillies", "Phaseera", "Uyter", "Kashyyyk", "Rakhuuun", "Chamble", "Messert", "Randon", } },
    { name = "Lesser Lantillian Route", planets = { "Zeltros", "Merson", "Taboon", "Ambria", "Onderon & Dxun", "Porus Vida", "Vena", "Nazzri", "Avenelle", "Uyter", "Togoria", "Charros", "Bimmisaari", "Peg Shar", "Pusat Station", "Boonta", "Junkfort Station", "Dagelin Minor", "Oseon", "Scillal", "Lekua", "Cadma", "Zebitrope", } },
    { name = "Great Kashyyyk Branch", planets = { "Zeltros", "Virujansi", "Umbara", "Quas Killam", "Torn Station", "Kashyyyk", "Balamak", "Charros", } },
    { name = "Ado Spine", planets = { "Karfeddion", "Fengrine", "Neelanon", "Senex", "Rindao", "Parada", "Eiattu", "StarForge Nebula", "Indupar", "Medth", } },
    { name = "Nothoiin Corridor", planets = { "Dolla", "Eriadu", } },
    { name = "Triellus Trade Run", planets = { "Darkknell", "Sanrafsix", "Verdanth", "Alui", "Enarc", "Ryndellia", "Farstine", "Zhar", "Llanic", "Tythe", "Arkanis", } },
    { name = "Duros Space Run", planets = { "Enarc", "Bannistar Station", "Triffis", "Kalarba", "New Cov", } },
    { name = "Sanrafsix Corridor", planets = { "Sanrafsix", "Syned", "Omwat", "Kabal", "Dravian Station", "Sevarcos", "Kirdo", "Ma'ar Shaddam", "Cotellier", } },
    { name = "Llanic Spice Run", planets = { "Farstine", "Ninzan", "Trigalis", "Stend", "Vergesso", "Bajic", "Vohai", "Elshandruu Pica", "Suarbi", "Skynara", "Spice Terminus", "Reuss", "Andalasa", "Bahalian", "Socorro", "Llanic", "Mon Gazza", } },
    { name = "Celanon Spur", planets = { "Dorin", "Myomar", "Vicondor", "Station 88", "Vortex", "Nentan", "Dohu", "Qiilura", "Ord Mantell", "Korvaii", "Ithor", "Noonar", "Cademimu", "Agamar", "Shaum Hii", "Vinsoth", "Drackmar", "Botajef", } },
    { name = "Listehol Run", planets = { "Listehol", "Mirial", "Sikurd", "Gigor", "Zygerria", } },
    { name = "Shaltin Tunnels", planets = { "Mytus", "Ulicia", "Atchorb", "D'ian", "Etti", "Ession", "Kalla", "Pondut Station", "Cantonica", "Oslumpex", "Zygerria", "Ranroon", "Syngia", "Lianna", } },
    { name = "Overic Griplink", planets = { "Mon Calamari", "Ruisto", "Reginard", "Munto Codru", "Turkana", "Shaylin", "Pakuuni", "Florn", "Toola", "Quermia", } },
    { name = "Way Of Schesa", planets = { "The Redoubt", "Pesfavri", "Schesa", "Noris", "Ornfra", } },
    { name = "Path Of The Houses", planets = { "Noris", "Sharb", "Ornfra", "Naporar", "Sposia", "Csilla", "Cioral", "Sarvchi", "Copero", "Csaus", "Rhigar", } },
    { name = "Ansion Spur", planets = { "Keitum", "Ansion", "Gilatter", "Sinton", "Rago", "Murgo", "Utegetu Nebula", } },
    { name = "Shwuy Exchange", planets = { "Vakkar", "Palanhi", "Noquivzor", "Ord Antalaha", "Dankayo", "Uviuy Exen", } },
    { name = "Entralla Route", planets = { "Endoraan", "Entralla", "Capza", "Yaga Minor", "Ompersan", "Prefsbelt", "Borosk", "JanFathal", "Wistril", "Orinda", "Lonnaw", "Obredaan", "Gonmore", "Ord Tessebok", "Yout", "Qiilura", } },
    { name = "Pabol Hutta", planets = { "Nal Hutta & Nar Shaddaa", "Hosko", "Varl", "Gos Hutta", "Mulatan", "Sleheyron", "Sriluur", "Boonta", } },
    { name = "Shag Pabol", planets = { "Teth", "Lirra", "Outland Transit", "Ziugen", "Ylesia", "Diyu", "Rorak", "Nal Hutta & Nar Shaddaa", } },
    { name = "Ootmian Pabol", planets = { "Du Hutta", "Irith", "Nar Bo Sholla", "Keldooine", "Kwenn", "Ubrikkia", "Blimph", "Randon", } },
    { name = "Varl Run", planets = { "Varl", "M'Hanna", "Tisht", "Saqqar", "Usk", "Elgit", "Zisia", "Ulmatra", "Kafane", "Nimia", "Yoribuunt", } },
    { name = "Kegan Run", planets = { "Kegan", "Delacrix", "Yoribuunt", "Ques", "Sriluur", "Boonta", } },
    { name = "Commenor Run", planets = { "Brentaal", "Tepasi", "Korfo", "Caamas", "Alderaan", "Tyed Kant", "Parkis", "Kattada", "Uquine", "Commenor", } },
    { name = "Trellent Trade Route", planets = { "Trellen", "Humbarine", "Commenor", } },
    { name = "Fedalle Run", planets = { "Fedalle", "Raxxa", "Kuat", "Commenor", } },
    { name = "Quellor Run", planets = { "Commenor", "Damoria", "Chorax", "Vladet", "Cato Neimoidia", "Hensara", "Talasea", "Lankashiir", "Quellor", } },
    { name = "Nanth'ri Route", planets = { "Exodeen", "Quellor", "Antar", "Gyndine", "Fabrin", "Mimban", "Zaloriis", "Attahox", "Nanth'ri", } },
    { name = "Lorell Route", planets = { "Zeltros", "Andalia", "Sennex", "Daruvvia", "Ket", "Lovola", "Maires", "Vergill", } },
    { name = "Hapan Spine", planets = { "Taanab", "Roqoo Depot", "Terephon", "Zalori", } },
    { name = "Rynmar Trail", planets = { "Modus", "Sargon", "Febrini", "Rynmar", "Zalori", } },
    { name = "Trellen Trade Route", planets = { "Commenor", "Rasterous", "Zeltros", "Virujansi", "Umbara", "Quas Killam", "Torn Station", "Kashyyyk", } },
    { name = "Trax Tube", planets = { "Daalang", "Nixor", "Nanth'ri", "Uogo'cor", "Lexrul", "Deysum", "Randon", } },
    { name = "Terr'Skiar Pass", planets = { "Terr'Skiar", "Bissillirus", "Deysum", } },
}

set maxvar 64000
use "/slade/projects/UKBB/phenotype_data/master/derived_data/Unrelated_EUR/Unrelated_Eur_500K.dta" 

generate unr_eur = 1
label variable unr_eur "Unrelated European individual"

merge 1:1 n_eid using "/slade/projects/UKBB/phenotype_data/master/main_data/ukb_first_occurrences.dta", keepusing (n_eid ts_131036_0_0 ts_130836_0_0) generate(_merge_insr)
drop _merge_insr

merge 1:1 n_eid using "/slade/projects/UKBB/phenotype_data/master/main_data/raw_data_2019.dta", keepusing (n_eid ts_53_0_0 n_21003_0_0 n_52_0_0 n_34_0_0 n_399_0_2 n_20016_0_0 n_4282_0_0 n_20018_0_0 n_20023_0_0 n_1845_0_0 n_2946_0_0 n_20107* n_20110* n_31_0_0 n_1239_0_0 n_1249_0_0 n_189_0_0 n_6138_0* n_738_0_0 n_5364_0_0 n_1588_0_0 n_1578_0_0 n_1608_0_0 n_1568_0_0 n_1598_0_0 n_6142_0* n_884_0_0 n_894_0_0 n_904_0_0 n_914_0_0 n_20001_0_* n_20002_0_*) generate (_merge_insr)
drop _merge_insr

merge 1:1 n_eid using "/slade/home/hm626/APOE.haplotype.9072.dta", keepusing (n_eid apoe) generate (_merge_insr)
drop _merge_insr

replace unr_eur = 0 if unr_eur==.

*---------------date of first report for relevant diagnoses---------------
rename ts_131036_0_0 fr_ad_G30
rename ts_130836_0_0 fr_ad_dementia_F00

*---------------flag if patient has been diagnosed with AD (with or without dementia)---------------
generate diagnosed_ad_overall =.
label variable diagnosed_ad_overall "Patient has been diagnosed with AD (with or without dementia)"
replace diagnosed_ad_overall = 1 if fr_ad_G30 !=. | fr_ad_dementia_F00 !=.
replace diagnosed_ad_overall = 0 if diagnosed_ad_overall ==.

*---------------assessment dates and participant age/d.o.b.---------------
rename ts_53_0_0 baseline_date
rename n_21003_0_0 baseline_age
rename n_52_0_0 month_of_birth
rename n_34_0_0 year_of_birth

*****age at first report of AD diagnosis calculated below, by modifying code taken from /slade/projects/UKBB/phenotype_data/scripts/do_files/generate_age_in_days_years_by_month.do
*---------------generate approx. patient d.o.b. (assuming 15th day of month)---------------
generate day = 15
generate date_of_birth_approx = mdy(month_of_birth,day,year_of_birth)
generate ed_month_of_birth = mofd(date_of_birth_approx)

*---------------age at first report of AD diagnosis---------------
foreach x of varlist fr_ad* {
 generate year_`x' = year(`x')
 generate month_`x' = month(`x')
 generate approx_`x' = mdy(month_`x',day,year_`x')
 generate ed_month_`x' = mofd(approx_`x')
 generate month_age_`x' = ed_month_`x' - ed_month_of_birth
 generate year_age_`x' = month_age_`x'/12
 drop year_`x' month_`x' approx_`x' ed_month_`x' month_age_`x'
 label variable year_age_`x' "Age at first diagnosis"
 replace year_age_`x' = 0 if year_age_`x' ==.
}

*---------------identify if AD is EOAD or LOAD---------------
generate age_earliest_ad_diagnosis =.
label variable age_earliest_ad_diagnosis "Patient age at earliest date of AD diagnosis (with or without dementia)
replace age_earliest_ad_diagnosis = year_age_fr_ad_dementia_F00 if (year_age_fr_ad_dementia_F00 <= year_age_fr_ad_G30 & year_age_fr_ad_dementia_F00 != 0) | (year_age_fr_ad_G30 == 0 & year_age_fr_ad_dementia_F00 != 0)
replace age_earliest_ad_diagnosis = year_age_fr_ad_G30 if (year_age_fr_ad_G30 < year_age_fr_ad_dementia_F00 & year_age_fr_ad_G30 != 0) | (year_age_fr_ad_G30 != 0 & year_age_fr_ad_dementia_F00 == 0)

generate eoad =.
label variable eoad "Patient has been diagnosed with EOAD"
replace eoad = 1 if diagnosed_ad_overall == 1 & age_earliest_ad_diagnosis < 65
replace eoad = 0 if eoad ==.

generate load =.
label variable load "Patient has been diagnosed with LOAD"
replace load = 1 if diagnosed_ad_overall == 1 & age_earliest_ad_diagnosis >= 65
replace load = 0 if load ==.

generate ad_type =.
label variable ad_type "EOAD/LOAD"
replace ad_type = 1 if load == 1
replace ad_type = 0 if eoad == 1

*---------------cognitive tests---------------
rename n_399_0_2 incorrect_pairs_baseline
rename n_20016_0_0 fi_baseline
rename n_4282_0_0 num_mem_baseline
rename n_20018_0_0 pros_mem_result
rename n_20023_0_0 reaction_time_baseline

*---------------log transform pairs matching data---------------
generate incorrect_pairs_baseline_log =.
label variable incorrect_pairs_baseline_log "Log of pairs matching result at baseline (baseline visit only)"
replace incorrect_pairs_baseline_log=log(incorrect_pairs_baseline + 1)

*---------------log transform reaction time data---------------
generate reaction_time_baseline_log =.
label variable reaction_time_baseline_log "Log of reaction time result at baseline"
replace reaction_time_baseline_log=log(reaction_time_baseline)

*---------------remove numeric memory results where test abandoned---------------
replace num_mem_baseline =. if num_mem_baseline == -1

*---------------change prospective memory result to 0/1---------------
generate pros_mem_baseline =.
label variable pros_mem_baseline "Prospective memory result (1 = correct first time / 0 = not correct first time)"
replace pros_mem_baseline=1 if pros_mem_result == 1
replace pros_mem_baseline=0 if pros_mem_result != 1 & pros_mem_result!=.

*---------------parent age at baseline---------------
rename n_1845_0_0 mother_age_baseline
rename n_2946_0_0 father_age_baseline

*---------------parent AD---------------
generate father_ad =.
label variable father_ad "Father has Alzheimer's disease"
foreach x of varlist n_20107* {
replace father_ad = 1 if `x'==10
}
replace father_ad = 0 if father_ad ==.

generate mother_ad =.
label variable mother_ad "Mother has Alzheimer's disease"
foreach x of varlist n_20110* {
replace mother_ad = 1 if `x'==10
}
replace mother_ad = 0 if mother_ad ==.

generate parent_ad =.
label variable parent_ad "At least one parent has AD"
replace parent_ad = 1 if mother_ad ==1 | father_ad==1
replace parent_ad = 0 if parent_ad ==.

*---------------covariates---------------
rename n_31_0_0 sex
rename n_1239_0_0 current_smoking
rename n_1249_0_0 past_smoking
rename n_189_0_0 tdi_socioeconomic
rename n_738_0_0 income
rename n_1588_0_0 alcohol_beer_cider_weekly
rename n_1578_0_0 alcohol_champage_wine_weekly
rename n_1608_0_0 alcohol_fortified_wine_weekly
rename n_1568_0_0 alcohol_red_wine_weekly
rename n_1598_0_0 alcohol_spirits_weekly
rename n_5364_0_0 alcohol_other_weekly
rename n_884_0_0 moderate_activity_sessions
rename n_894_0_0 moderate_activity_mins
rename n_904_0_0 vigorous_activity_sessions
rename n_914_0_0 vigorous_activity_mins

*---------------determine current smoking status---------------
generate smoking_status =.
label variable smoking_status "Smoking status at baseline (1 = current smoker / 2 = past smoker / 0 = non-smoker)"
*****current_smoking - 1 = yes / 2 = occasionally / 0 = No / -3 = not answered, treated as missing data
replace smoking_status = 1 if current_smoking == 1 | current_smoking == 2
*****past_smoking - 1 = most days / 2 = occasionally / 3 = tried / 4 = never / -3 = not answered, treated as missing data
replace smoking_status = 2 if smoking_status ==. & (past_smoking == 1 | past_smoking == 2 | past_smoking == 3)
replace smoking_status = 0 if smoking_status ==. & (current_smoking == 0 | (past_smoking == 4 & current_smoking == -3))

*---------------determine education level at baseline---------------
generate education_level =.
label variable education_level "College/uni degree = 1 / no degree = 0"
foreach x of varlist n_6138* {
replace education_level = 1 if `x'==1
}

replace education_level = 0 if education_level ==.

*---------------income - remove don't know / prefer not to say answers - treat as missing data---------------
generate income_corrected =.
label variable income_corrected "Yearly income (corrected to remove don't know / prefer not to say)"
replace income_corrected = income if income !=-1 & income !=-3

*---------------calculate weekly servings of alcohol---------------
*****missing values treated as 0 otherwise sum doesn't work
foreach x of varlist alcohol_* {
replace `x' = 0 if `x'==.|`x'==-1|`x'==-3
}
generate total_alcohol_weekly =.
label variable total_alcohol_weekly "Sum of all alcoholic drink servings weekly"
replace total_alcohol_weekly = alcohol_beer_cider_weekly + alcohol_champage_wine_weekly + alcohol_fortified_wine_weekly + alcohol_red_wine_weekly + alcohol_spirits_weekly + alcohol_other_weekly

*---------------determine employment status---------------
*****those who selected both "in employment" and "retired" are categorised as in employment
generate employment_status =.
label variable employment_status "employed = 1 / retired = 2 / other = 0"
foreach x of varlist n_6142* {
replace employment_status = 1 if `x'==1 
}

foreach x of varlist n_6142* {
replace employment_status = 2 if `x'==2 & employment_status==.
}

replace employment_status = 0 if employment_status ==.

*---------------calculate minutes of physical activity per week---------------
generate exercise_mins_week = 0
label variable exercise_mins_week "Total mins of moderate/vigorous activity per week"
*****flag genuine missing data -i.e. all info for moderate/physical activity not provided
replace exercise_mins_week =. if (moderate_activity_mins ==. | moderate_activity_mins ==-1 | moderate_activity_mins ==-3) & (moderate_activity_sessions ==. | moderate_activity_sessions ==-1 | moderate_activity_sessions ==-3) & (vigorous_activity_mins ==. | vigorous_activity_mins ==-1 | vigorous_activity_mins ==-3) & (vigorous_activity_sessions ==. | vigorous_activity_sessions ==-1 | vigorous_activity_sessions ==-3)

*****other unknown/missing values treated as 0 otherwise calculation doesn't work (if not already flagged as missing data)
replace moderate_activity_mins = 0 if (moderate_activity_mins ==. | moderate_activity_mins ==-1 | moderate_activity_mins ==-3) & exercise_mins_week !=.
replace vigorous_activity_mins = 0 if (vigorous_activity_mins ==. | vigorous_activity_mins ==-1 | vigorous_activity_mins ==-3) & exercise_mins_week !=.
replace moderate_activity_sessions = 0 if (moderate_activity_sessions ==. | moderate_activity_sessions ==-1 | moderate_activity_sessions ==-3) & exercise_mins_week !=.
replace vigorous_activity_sessions = 0 if (vigorous_activity_sessions ==. | vigorous_activity_sessions ==-1 | vigorous_activity_sessions ==-3) & exercise_mins_week !=.

*****calculate final value for minutes of physical activity
replace exercise_mins_week = (moderate_activity_sessions*moderate_activity_mins) + (vigorous_activity_sessions*vigorous_activity_mins) if exercise_mins_week !=.

*---------------self-reported AD/dementia at baseline---------------
generate AD_baseline =.
label variable AD_baseline "Individuals self-reporting AD/dementia/cognitive impairment at baseline"
foreach x of varlist n_20002* {
replace AD_baseline=1 if `x'==1263
}
replace AD_baseline=0 if AD_baseline==.

*---------------self-reported condition at baseline which affects cognition (excluding AD)---------------
generate neurological_condition_baseline =.
label variable neurological_condition_baseline "Individuals self-reporting a neurological condition at baseline"
local I "1032 1491 1245 1425 1433 1258 1246 1264 1266 1244 1583 1031 1659 1247 1259 1261 1240 1683 1397 1434 1262 1524 1081 1086 1083 1082"
foreach x of varlist n_2000* {
foreach C of local I {
replace neurological_condition_baseline=1 if `x'==`C'
}
}
replace neurological_condition_baseline=0 if neurological_condition_baseline==.

*---------------remove withdrawn participants---------------
*****this .do file shows withdrawn up to feb 2021 - raw data.dta withdrawn column label says up to feb 2020, so using .do file (already existing on the server) for more up to date info
do /slade/projects/UKBB/phenotype_data/scripts/do_files/withdrawn_participants.do
drop if withdrawn == 1
drop withdrawn

*---------------flag participants with APP/PSEN1/PSEN2 variants---------------
*****separate .do file used due to inclusion of participant IDs and need to not upload these to Github
do /slade/home/hm626/EOFAD_study_participants.do

*---------------identify APOE genotype/alleles in each participant---------------
generate e2_e2 =.
label variable e2_e2 "Individual has the APOE e2/e2 genotype - 1 = true / 0 = false"
replace e2_e2 = 1 if apoe == 4
replace e2_e2 = 0 if e2_e2 ==. & apoe !=.

generate e2_e3 =.
label variable e2_e3 "Individual has the APOE e2/e3 genotype - 1 = true / 0 = false"
replace e2_e3 = 1 if apoe == 5
replace e2_e3 = 0 if e2_e3 ==. & apoe !=.

generate e2_e4 =.
label variable e2_e4 "Individual has the APOE e2/e4 genotype - 1 = true / 0 = false"
replace e2_e4 = 1 if apoe == 6
replace e2_e4 = 0 if e2_e4 ==. & apoe !=.

generate e3_e3 =.
label variable e3_e3 "Individual has the APOE e3/e3 genotype - 1 = true / 0 = false"
replace e3_e3 = 1 if apoe == 7
replace e3_e3 = 0 if e3_e3 ==. & apoe !=.

generate e3_e4 =.
label variable e3_e4 "Individual has the APOE e3/e4 genotype - 1 = true / 0 = false"
replace e3_e4 = 1 if apoe == 8
replace e3_e4 = 0 if e3_e4 ==. & apoe !=.

generate e4_e4 =.
label variable e4_e4 "Individual has the APOE e4/e4 genotype - 1 = true / 0 = false"
replace e4_e4 = 1 if apoe == 9
replace e4_e4 = 0 if e4_e4 ==. & apoe !=.

generate e2_allele =.
label variable e2_allele "Individual carries an APOE e2 allele - 1 = true / 0 = false"
replace e2_allele = 1 if apoe == 4 | apoe == 5 | apoe == 6
replace e2_allele = 0 if e2_allele ==. & apoe !=.

generate e3_allele =.
label variable e3_allele "Individual carries an APOE e3 allele - 1 = true / 0 = false"
replace e3_allele = 1 if apoe == 5 | apoe == 7 | apoe == 8
replace e3_allele = 0 if e3_allele ==. & apoe !=.

generate e4_allele =.
label variable e4_allele "Individual carries an APOE e4 allele - 1 = true / 0 = false"
replace e4_allele = 1 if apoe == 6 | apoe == 8 | apoe == 9
replace e4_allele = 0 if e4_allele ==. & apoe !=.

*---------------sequence quality based on IGV plot---------------
*****1 = good quality / 2 = bad quality
*****separate .do file used due to inclusion of participant IDs and need to not upload these to Github
do /slade/home/hm626/EOFAD_variants_IGV_quality.do

set pformat %5.2e

***************************************
* MIT License
* Copyright (c) 2022 Jinying Chen
*  
* author: Jinying Chen, UMass Chan Medical School
* date: 2022-7-14
* ver: 1.0 
* 
* This code was written to support data analysis for the s2s study.
* The code is for research use only, and is provided as it is.
* 
***************************************
* 
* To run the code:
*
* 1. Setting input data directory
* replace [[input dir]] in the definition of the global macro datadir in the file analyze_s2s_data.do 
* (around line 39) by the directory that holds the input file
*
* 2. Setting input data file
* replace [[data file]] in the definition of the global macro allsurveys in the file analyze_s2s_data.do 
* (around line 40) by the input file (in Stata data format)
*
* 3. Program running order
* (1) prepare_data -> table_1, table_2, table_3
* (2) identify_unbalance_mi -> generate_mi_4grp -> table_2_mi, table_3_mi
*
*

capture program drop prepare_data
capture program drop table_1
capture program drop table_2
capture program drop table_3
capture program drop identify_unbalance_mi
capture program drop generate_mi_4grp
capture program drop table_2_mi
capture program drop table_3_mi

global datadir [[input_dir]]
global allsurveys [[data_file]]

// baseline: smokinginlast12months
// 6month outcome: current_smoke quitattempts cigs_per_day
// label define r4code_ 
// 1 "A Fully enhanced (both peer recruitment and recommender CTHC)" 
// 2 "B Recommender CTHC only (No Peer Recruitment Tools)" 
// 3 "C Peer Recruitment tools Only (standard CTHC)" 
// 4 "D Standard (No Peer Recruitment Tools and standard CTHC)" 

global baseline_var sex* age* race* highestgradeofschool* education referralsource paymedicalcare ///
homecigarettesperday* smokingstatus_b* frfm testuser

mkdir mi_data/

// recoding groups/conditions for answering different research questions
program prepare_data
	use "$datadir/$allsurveys.dta", clear
	tab r4code
	
	gen r2code = r4code
	replace r2code = 0 if r4code != 1
	label define r2code_l 1 "Fully enhanced" 0 "Other"
	label value r2code r2code_l 
	
	gen cigperday = homecigarettesperday 
	replace cigperday = 75 if homecigarettesperday != . & homecigarettesperday > 75
	
	gen cigperday_3cat = .
	replace cigperday_3cat = 1 if homecigarettesperday <= 5
	replace cigperday_3cat = 2 if homecigarettesperday > 5 & homecigarettesperday <= 20
	replace cigperday_3cat = 3 if homecigarettesperday >= 21 & homecigarettesperday != .
	label define cigperday_3cat_l 1 "0-5" 2 "6-20" 3 ">= 21"
	labe value cigperday_3cat cigperday_3cat_l 
	
	gen age_3cat = .
	replace age_3cat = 1 if age_r <= 2
	replace age_3cat = 2 if age_r == 3 | age_r == 4
	replace age_3cat = 3 if age_r == 5 | age_r == 6
	label define age_3cat_l 1 "19-34" 2 "35-54" 3 ">= 55"
	label value age_3cat age_3cat_l 
	tab age_3cat age_r
	
	gen smkstatus_b_3cat = .
	replace smkstatus_b_3cat = 1 if smokingstatus_b == "I am not thinking about quitting"
	replace smkstatus_b_3cat = 2 if regexm(smokingstatus_b, "(thinking of quit)|(set a)") 
	replace smkstatus_b_3cat = 3 if regexm(smokingstatus_b, "(quit today)|(already quit)")
	tab smokingstatus_b smkstatus_b_3cat 
	label define smkstatus_l 1 "not thinking quit" 2 "thinking quit or set a quit day" 3 "quit today or have quit"
	label value smkstatus_b_3cat smkstatus_l 
	
	gen smkstatus_3cat = .
	replace smkstatus_3cat = 1 if smokestatus == 1
	replace smkstatus_3cat = 2 if smokestatus == 2 | smokestatus == 3
	replace smkstatus_3cat = 3 if smokestatus == 4 | smokestatus == 5
	label value smkstatus_3cat smkstatus_l 
	tab smokestatus smkstatus_3cat 
	
	gen race_3cat = .
	replace race_3cat = 2 if race_r == 0
	replace race_3cat = 1 if race_r == 1
	replace race_3cat = 3 if race_r >= 2 & race_r <= 4
	label define race_l 1 "African American" 2 "White" 3 "Others"
	label value race_3cat race_l 
	tab race_3cat race_r
	
	gen paymed_3cat = .
	replace paymed_3cat = 1 if paymedicalcare == 1 | paymedicalcare == 2
	replace paymed_3cat = 2 if paymedicalcare == 3
	replace paymed_3cat = 3 if paymedicalcare == 4
	label define paymed_3cat_l 1 "hard/very hard" 2 "somewhat hard" 3 "not very hard"
	label value paymed_3cat paymed_3cat_l 
	
	gen edu_3cat = .
	replace edu_3cat = 1 if highestgradeofschool_r <= 2
	replace edu_3cat = 2 if highestgradeofschool_r == 3
	replace edu_3cat = 3 if highestgradeofschool_r == 4
	label define edu_3cat_l 1 "high school or lower" 2 "some college" 3 "college graduate"
	label value edu_3cat edu_3cat_l 
		
	gen group_peer = .
	replace group_peer = 1 if r4code == 1 | r4code == 3
	replace group_peer = 2 if r4code == 2 | r4code == 4
	label define group_peer_l 1 "with peer recruit tool" 2 "without peer recruit tool"
	label value group_peer group_peer_l
	
	gen group_rec = .
	replace group_rec = 1 if r4code == 1 | r4code == 2
	replace group_rec = 2 if r4code == 3 | r4code == 4
	label define group_rec_l 1 "with recommender system" 2 "without recommender system"
	label value group_rec group_rec_l
	
	// referred by friends/family
	gen refer_by_peer = .
	replace refer_by_peer = 1 if regexm(referralsource, "Friend") == 1
	replace refer_by_peer = 0 if regexm(referralsource, "Friend") == 0 & referralsource != ""
	label define refer_l 1 "referred by friends or family" 0 "other recruitment methods" 
	label value refer_by_peer refer_l
	
	gen recruit_grp3 = .
	replace recruit_grp3 = 1 if r4code == 2 | r4code == 4
	replace recruit_grp3 = 2 if r4code == 1 | r4code == 3
	replace recruit_grp3 = 3 if recruit_grp3 == 2 & refer_by_peer == 1
	label define recruit_grp3_l 1 "without peer recruit tool" 2 "with peer recruit tool, other" ///
	3 "with peer recruit tool, by family/friends"
	label value recruit_grp3 recruit_grp3_l
	

	// curr_smoke
	gen curr_smoke2 = curr_smoke
	replace curr_smoke2 = 1 if curr_smoke == .
	
	// 7dayQuit
	gen quit7day = 1 - curr_smoke
	gen quit7day2 = 1 - curr_smoke2
	label define quit7day_l  1 "quit" 0 "not quit"
	label value quit7day quit7day_l
	label value quit7day2 quit7day_l
	
	
	save "$datadir/${allsurveys}_update.dta", replace
	export excel using "$datadir/${allsurveys}_update.xlsx", sheet("allvar") firstrow(variables) replace
end

// identify unbalanced participant characteristics across different conditions
program define table_1
	*** smoker characteristics by outcome ***
	use "$datadir/${allsurveys}_update.dta", clear

	table1, by(r4code) vars (age_r cat \ sex cat \ ///
	race_blackorafricanamerican cat \ highestgradeofschool_r cat \ ///
	paymedicalcare cat \ ///
	smkstatus_b_3cat cat \ smkstatus_3cat cat \ cigperday contn) ///
	format(%2.1f) saving(table1.xls, sheet(4grp_old) sheetreplace)	
	
	table1, by(r4code) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(table1.xls, sheet(4grp) sheetreplace)	
	
	table1, vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(table1.xls, sheet(all) sheetreplace)	
	
	dis "paired comparison"
	foreach i in 2 3 4 {
		dis "=== reference is group `i' ===" 
		table1 if r4code == `i' | r4code == 1, by(r4code) vars (age_3cat cat \ sex cat \ ///
		race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ paymed_3cat cat \  ///
		smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
		format(%2.1f) saving(table1.xls, sheet("1_vs_`i'") sheetreplace)	
	}
	
	
	table1, by(group_peer) vars (age_r cat \ sex cat \ ///
	race_blackorafricanamerican cat \ highestgradeofschool_r cat \ ///
	paymedicalcare cat \ ///
	smkstatus_b_3cat cat \ smkstatus_3cat cat \ cigperday contn) /// 
	format(%2.1f) saving(tableA1.xls, sheet(2grp_PR_old) sheetreplace)	
	
	table1, by(group_peer) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableA1.xls, sheet(2grp_PR) sheetreplace)	
	
	table1, by(group_rec) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableA1.xls, sheet(2grp_RECM) sheetreplace)	
	
	table1, by(refer_by_peer) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableA1.xls, sheet(2grp_referbypeer) sheetreplace)	
	
	table1, by(recruit_grp3) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableA1.xls, sheet(3grp_recruit) sheetreplace)	
	
 	//mdesc
	
end

// main analysis, factorial design
program define table_2
	use "$datadir/${allsurveys}_update.dta", clear
	
	dis "*** 2 x 2 factorial design ***"
	*** 2x2 factorial design ***
	tab group_peer quit7day, row
	tab group_rec quit7day, row
	
	// test interaction
	logistic quit7day b2.group_rec##b2.group_peer sex_r i.edu_3cat
	logistic quit7day2 b2.group_rec##b2.group_peer sex_r i.edu_3cat
	
	// complete case
	dis "* complete case *"
	logistic quit7day b2.group_rec b2.group_peer
	logistic quit7day b2.group_rec b2.group_peer sex_r i.edu_3cat
	
	// penalty imputation
	dis "* penalty imputation *"
	tab group_peer quit7day2, row
	tab group_rec quit7day2, row
	logistic quit7day2 b2.group_rec b2.group_peer 
	logistic quit7day2 b2.group_rec b2.group_peer sex_r i.edu_3cat
	
	
	*** 4 group, paired comparison ***
	dis "*** 4 groups, paired comparison ***"
	// complete case
	dis "* complete case *"
	tab r4code quit7day , row
	logistic quit7day ib(1).r4code 
	lincom _b[1.r4code] - _b[2.r4code], or
	lincom _b[1.r4code] - _b[3.r4code], or
	lincom _b[1.r4code] - _b[4.r4code], or
	
	logistic quit7day ib(1).r4code sex_r i.edu_3cat
	lincom _b[1.r4code] - _b[2.r4code], or
	lincom _b[1.r4code] - _b[3.r4code], or
	lincom _b[1.r4code] - _b[4.r4code], or
	
	
	// penalty imputation
	dis "* penalty imputation *"
	tab r4code quit7day2 , row
	logistic quit7day2 ib(1).r4code 
	lincom _b[1.r4code] - _b[2.r4code], or
	lincom _b[1.r4code] - _b[3.r4code], or
	lincom _b[1.r4code] - _b[4.r4code], or
	
	
	logistic quit7day2 ib(1).r4code sex_r i.edu_3cat
	lincom _b[1.r4code] - _b[2.r4code], or
	lincom _b[1.r4code] - _b[3.r4code], or
	lincom _b[1.r4code] - _b[4.r4code], or
	
	
	dis "*** full intervention (A) vs. all other ***"
	// complete case
	dis "* complete case *"
	tab r2code quit7day , row
	logistic quit7day r2code 
	logistic quit7day r2code sex_r i.edu_3cat
	
	// penalty imputation
	dis "* penalty imputation *"
	tab r2code quit7day2 , row
	logistic quit7day2 r2code 
	logistic quit7day2 r2code sex_r i.edu_3cat
	
	
	
	*** with vs. w/o recommender CTHC, excluding participants recruited by family/friends, balanced on baseline variables  ***
	dis "*** with vs. w/o recommender CTHC, excluding participants recruited by family/friends ***"
	drop if refer_by_peer == 1
	table1, by(group_rec) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ ///
	paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableA1.xls, sheet(2grp_RECM_noPeerRecruited) sheetreplace)	
	
	// complete case
	dis "* complete case *"
	tab group_rec quit7day, row
	logistic quit7day ib(2).group_rec 
	logistic quit7day ib(2).group_rec sex_r i.edu_3cat
	
	// penalty imputation
	dis "* penalty imputation *"
	tab group_rec quit7day2, row
	logistic quit7day2 ib(2).group_rec sex_r i.edu_3cat
	
	
end

program define table_3
	use "$datadir/${allsurveys}_update.dta", clear
	*** two groups ***
	// complete case
	tab refer_by_peer quit7day, row
	logistic quit7day refer_by_peer 
	logistic quit7day refer_by_peer sex_r i.edu_3cat
	logistic quit7day refer_by_peer i.age_3cat sex_r i.edu_3cat 
	
	// penalty imputation
	tab refer_by_peer quit7day2, row
	logistic quit7day2 refer_by_peer 
	logistic quit7day2 refer_by_peer sex_r i.edu_3cat
	logistic quit7day2 refer_by_peer i.age_3cat sex_r i.edu_3cat 
	
	
	*** three groups ***
	// complete case
	tab recruit_grp3 quit7day, row
	logistic quit7day i.recruit_grp3 
	logistic quit7day i.recruit_grp3 sex_r i.edu_3cat
	logistic quit7day i.recruit_grp3 i.age_3cat sex_r i.edu_3cat 
	
	// penalty imputation
	tab recruit_grp3 quit7day2, row
	logistic quit7day2 i.recruit_grp3 
	logistic quit7day2 i.recruit_grp3 sex_r i.edu_3cat
	logistic quit7day2 i.recruit_grp3 i.age_3cat sex_r i.edu_3cat 
	
end

program define identify_unbalance_mi
	use "$datadir/${allsurveys}_update.dta", clear
	
	keep r4code group_peer group_rec refer_by_peer recruit_grp3 quit7day age_3cat sex_r  ///
	race_3cat ethnicity_r edu_3cat paymed_3cat  ///
	smkstatus_b_3cat cigperday_3cat  
		
	gen missing = 0
	replace missing = 1 if quit7day == .
	
	mdesc
	
	tab r4code missing, row chi
	tab group_rec missing, row chi
	tab group_peer missing, row chi
	tab refer_by_peer missing, row chi
	tab recruit_grp3 missing, row chi
	
	*** unbalanced by missing vs. not missing outcome ***
	table1, by(missing) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableMI.xls, sheet(missing) sheetreplace)	
	// age_3cat, race_3cat, edu_3cat, cigperday_3cat
	
	*** unbalanced by outcome ***
	table1, by(quit7day) vars (age_3cat cat \ sex cat \ ///
	race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ paymed_3cat cat \  ///
	smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
	format(%2.1f) saving(tableMI.xls, sheet(outcome) sheetreplace)	
	// age_3cat, sex_r, edu_3cat, smkstatus_b_3cat
	
	*** unbalanced by treatment groups, among participants having outcomes ***
	foreach group in r4code group_peer group_rec refer_by_peer recruit_grp3 {
		table1 if missing == 0, by(`group') vars (age_3cat cat \ sex cat \ ///
		race_3cat cat \ ethnicity_r cat \ edu_3cat cat \ paymed_3cat cat \  ///
		smkstatus_b_3cat cat \ cigperday_3cat cat ) /// 
		format(%2.1f) saving(tableMI.xls, sheet("`group'") sheetreplace)	
	}
	// r4code: sex_r 
	// group_rec: sex_r, race_3cat
	// refer_by_peer: age_3cat, sex_r, edu_3cat
	// recruit_grp3: age_3cat, sex_r, edu_3cat
	
	foreach iv in age_3cat race_3cat edu_3cat smkstatus_b_3cat cigperday_3cat {
		tabulate `iv', generate("`iv'")
	}
	save mi_data/input_for_mi.dta, replace
	
end

program define generate_mi_4grp
	use mi_data/input_for_mi.dta, clear
	mi set flong
	mi register imputed quit7day race_3cat edu_3cat smkstatus_b_3cat
	mi impute chained (logit) quit7day (mlogit) race_3cat edu_3cat smkstatus_b_3cat ///
		 = sex_r age_3cat1 age_3cat2 cigperday_3cat1 cigperday_3cat2, ///
		 by(r4code) rseed(500) add(100) force noisily augment
	
	save mi_data/quit7day_mi_s100.dta, replace
	mi estimate, or dftable vartable: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
		
end


program define table_2_mi
	use mi_data/quit7day_mi_s100.dta, clear
	
	*** 4 group ***
	dis "*** 4 group ***"
	/*
	mi estimate, or dftable vartable: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	*/
	mi estimate, or vartable: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	
	dis "*** full intervention (A) vs. all other ***"
	gen r2code = r4code
	replace r2code = 0 if r4code != 1
	label define r2code_l 1 "Fully enhanced" 0 "Other"
	label value r2code r2code_l 
	
	mi estimate, or vartable: logistic quit7day r2code sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	
	*** paired comparison ***
	dis "paired comparison"
	mi estimate, or vartable post: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
		i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat 
	
	dis "* method 1*"
	lincom _b[1.r4code] - _b[2.r4code], or
	lincom _b[1.r4code] - _b[3.r4code], or
	lincom _b[1.r4code] - _b[4.r4code], or
	
	dis "* method 2*"
	mi estimate (_b[1.r4code] - _b[2.r4code]), or vartable: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
		i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	
	mi estimate (_b[1.r4code] - _b[3.r4code]), or vartable: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
		i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
		
	mi estimate (_b[1.r4code] - _b[4.r4code]), or vartable: logistic quit7day ib(1).r4code sex_r i.age_3cat ///
		i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
		
	*** with vs. w/o peer recruitment tool ***
	dis "*** with vs. w/o peer recruitment tool ***"
	
	*** with vs. w/o recommender CTHC ***
	dis "*** with vs. w/o recommender CTHC ***"
	mi estimate, or vartable: logistic quit7day ib(2).group_peer##ib(2).group_rec sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	
	mi estimate, or vartable: logistic quit7day ib(2).group_peer ib(2).group_rec sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	
		
	*** with vs. w/o recommender CTHC, excluding participants recruited by family/friends ***
	dis "*** with vs. w/o recommender CTHC, excluding participants recruited by family/friends ***"
	drop if refer_by_peer == 1
	mi estimate, or vartable: logistic quit7day ib(2).group_rec sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat

end


program define table_3_mi
	use mi_data/quit7day_mi_s100.dta, clear
	
	*** two groups ***
	mi estimate, or vartable: logistic quit7day refer_by_peer sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat

	
	*** three groups ***
	mi estimate, or vartable: logistic quit7day i.recruit_grp3 sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	

	dis "=== sensitivity analysis ==="
	*** two groups ***
	use mi_data/quit7day_mi_s100_referpeer.dta, clear
	mi estimate, or vartable: logistic quit7day refer_by_peer sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat

	
	*** three groups ***
	use mi_data/quit7day_mi_s100_recruit3grp.dta, clear
	mi estimate, or vartable: logistic quit7day i.recruit_grp3 sex_r i.age_3cat ///
	i.race_3cat i.edu_3cat i.smkstatus_b_3cat i.cigperday_3cat
	
end


/*
prepare_data
*/

/*
log using "table1.log", replace
table_1
log close
*/

/*
log using "table2.log", replace
table_2
log close
*/

/*
log using "table3.log", replace
table_3
log close
*/

/*
log using "unbalance_due_to_missingdata.log"
identify_unbalance_mi
log close
*/

/*
generate_mi_4grp
*/

/*
log using "table2_mi.log", replace
table_2_mi
log close
*/

/*
log using "table3_mi.log", replace
table_3_mi
log close
*/

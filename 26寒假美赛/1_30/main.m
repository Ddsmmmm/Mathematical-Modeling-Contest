% ============================================================
% DWTS scores hardcoded from 2026_MCM_Problem_C_Data.csv
% Column order (44 columns):
% [W1J1 W1J2 W1J3 W1J4  W2J1 W2J2 W2J3 W2J4  ...  W11J1 W11J2 W11J3 W11J4]
% N/A -> NaN; 0 remains 0.
% Each season matrix ends with 5 empty rows (NaN).
% ============================================================

% ===================== Season 1 =====================
season1_names = {
    "John O'Hurley"
    "Kelly Monaco"
    "Evander Holyfield"
    "Rachel Hunter"
    "Joey McIntyre"
    "Trista Sutter"
};

season1_scores = [
    7 7 6 NaN, 8 9 9 NaN, 9 8 7 NaN, 7 8 6 NaN, 9 9 9 NaN, 9 9 9 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    5 4 4 NaN, 5 6 6 NaN, 6 7 8 NaN, 9 9 8 NaN, 8.5 7.5 7.5 NaN, 8.5 9.5 9.5 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    5 7 6 NaN, 5 4 5 NaN, 5 4 4 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    7 6 7 NaN, 8 8 8 NaN, 8 9 9 NaN, 7 9 9 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    7 7 6 NaN, 8 7 6 NaN, 7 7 8 NaN, 7 6 7 NaN, 8.5 7 7 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    6 6 6 6, 6 7 6 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN
];
season1_scores = [season1_scores; NaN(5,44)];  % 预留 5 空行

% ===================== Season 2 =====================
season2_names = {
    "Tatum O'Neal"
    "Tia Carrere"
    "George Hamilton"
    "Lisa Rinna"
    "Stacy Keibler"
    "Jerry Rice"
    "Giselle Fernandez"
    "Master P"
    "Drew Lachey"
    "Kenny Mayne"
};

season2_scores = [
    7 8 8 NaN, 5 6 6 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    6 7 7 NaN, 7 8 7 NaN, 9 8 9 NaN, 9 8 8 NaN, 7 7 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    7 5 6 NaN, 8 7 7 NaN, 7 7 8 NaN, 7 7 7 NaN, 8 8 8 NaN, 8 7 8 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    5 7 7 NaN, 6 7 7 NaN, 8 8 9 NaN, 9 9 8 NaN, 7 9 9 NaN, 9 9 9 NaN, 8.5 9 9 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    8 6 8 NaN, 9 10 10 NaN, 9 9 9 NaN, 8 9 9 NaN, 10 10 10 NaN, 10 10 10 NaN, 9 9 9.5 NaN, 9.3333 9.6666 9.6666 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 7 8 8 NaN, 7 6 6 NaN, 8 8 8 NaN, 7 8 8 NaN, 8 7 8 NaN, 7 7 6.5 NaN, 9 9 8.6666 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    7 8 8 NaN, 8 8 8 NaN, 7 8 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    4 4 4 NaN, 6 5 5 NaN, 6 4 4 NaN, 4 2 2 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 9 9 9 NaN, 9 9 9 NaN, 9 9 10 NaN, 9 9 9 NaN, 10 10 10 NaN, 9.5 9 9 NaN, 9.6666 9.6666 9.6666 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN;
    4 5 4 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN, NaN NaN NaN NaN, NaN NaN NaN NaN
];
season2_scores = [season2_scores; NaN(5,44)];

% ===================== Season 3 =====================
season3_names = {
    "Harry Hamlin"
    "Vivica A. Fox"
    "Monique Coleman"
    "Joey Lawrence"
    "Mario Lopez"
    "Emmitt Smith"
    "Shanna Moakler"
    "Willa Ford"
    "Sara Evans"
    "Jerry Springer"
    "Tucker Carlson"
};

season3_scores = [
    5 6 6 NaN, 7 7 7 NaN, 7 8 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 8 8 NaN, 8 8 8 NaN, 9 9 9 NaN, 8 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 6 7 NaN, 9 8 9 NaN, 9 9 9 NaN, 8 8 8 NaN, 9 9 9 NaN, 9 7 7 NaN, 9 9 9 NaN, 8.5 9 9 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 10 9 10 NaN, 8 6 8 NaN, 9 9 9 NaN, 8 8 9 NaN, 8 8 8 NaN, 9.5 9 10 NaN, 9.5 8.5 9 NaN, 9.5 10 10 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    9 8 9 NaN, 7 6 8 NaN, 8 6 8 NaN, 10 9 10 NaN, 9 9 9 NaN, 9 9 10 NaN, 9.5 9 9.5 NaN, 9.5 9 10 NaN, 10 9.5 10 NaN, 10 10 9.6666 NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 8 8 8 NaN, 7 6 6 NaN, 8 8 8 NaN, 9 9 9 NaN, 8 8 9 NaN, 10 9.5 9 NaN, 8.5 9 9.5 NaN, 9.5 10 10 NaN, 10 9.6666 10 NaN, NaN NaN NaN NaN;
    7 5 6 NaN, 8 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 8 NaN, 7 8 8 NaN, 7 7 8 NaN, 9 9 10 NaN, 9 9 9 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    5 5 5 NaN, 7 7 7 NaN, 8 9 8 NaN, 6 7 7 NaN, 8 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    5 5 6 NaN, 7 6 6 NaN, 7 7 7 NaN, 7 7 8 NaN, 8 8 8 NaN, 7 6 5 NaN, 7.5 8 7.5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    5 4 3 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN
];
season3_scores = [season3_scores; NaN(5,44)];

% ===================== Season 4 =====================
season4_names = {
    "John Ratzenberger"
    "Ian Ziering"
    "Clyde Drexler"
    "Laila Ali"
    "Apolo Anton Ohno"
    "Shandi Finnessey"
    "Paulina Porizkova"
    "Heather Mills"
    "Billy Ray Cyrus"
    "Joey Fatone"
    "Leeza Gibbons"
};

season4_scores = [
    6 5 6 NaN, 7 7 7 NaN, 7 6 7 NaN, 6 5 5 NaN, 6 6 6 NaN, 7 6 6 NaN, 7.5 7.5 7.5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 7 8 7 NaN, 8 8 8 NaN, 7 9 8 NaN, 8 8 8 NaN, 8 8 8 NaN, 9 9 9 NaN, 8 7.5 8 NaN, 9.5 10 9.5 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 5 5 NaN, 6 6 6 NaN, 6 5 5 NaN, 6 4 5 NaN, 4 5 4 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 8 8 NaN, 9 9 9 NaN, 7 7 7 NaN, 7 7 7 NaN, 9 10 9 NaN, 9 9 10 NaN, 10 9.5 10 NaN, 9 8.5 9 NaN, 10 10 10 NaN, 9.6666 9 9.6666 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 8 9 9 NaN, 7 8 8 NaN, 9 8 9 NaN, 10 10 10 NaN, 9 9 10 NaN, 9 8.5 9.5 NaN, 10 9 10 NaN, 10 9.5 10 NaN, 9.6666 9.6666 10 NaN, NaN NaN NaN NaN;
    6 6 7 NaN, 6 7 7 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 6 7 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 6 6 NaN, 8 8 8 NaN, 8 8 8 NaN, 7 8 8 NaN, 7 7 7 NaN, 7 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    5 4 4 NaN, 7 7 7 NaN, 7 7 7 NaN, 7 7 7 NaN, 6 6 5 NaN, 7 7 7 NaN, 6 6.5 6.5 NaN, 6.5 6.5 6 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 8 8 8 NaN, 8 8 8 NaN, 10 9 9 NaN, 8 8 9 NaN, 9 9 9 NaN, 10 9.5 10 NaN, 9.5 9 9 NaN, 10 10 10 NaN, 9.6666 9.3333 9.6666 NaN, NaN NaN NaN NaN;
    5 5 5 NaN, 7 7 7 NaN, 8 8 8 NaN, 6 5 5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN
];
season4_scores = [season4_scores; NaN(5,44)];

% ===================== Season 5 =====================
season5_names = {
    "Cameron Mathison"
    "Jane Seymour"
    "Sabrina Bryan"
    "Jennie Garth"
    "Floyd Mayweather Jr."
    "Josie Maran"
    "Albert Reed"
    "Helio Castroneves"
    "Mel B"
    "Wayne Newton"
    "Marie Osmond"
    "Mark Cuban"
};

season5_scores = [
    7 7 7 NaN, 7 7 7 NaN, 8 7 8 NaN, 9 9 9 NaN, 8 9 9 NaN, 9 8 8 NaN, 8.5 8.5 8.5 NaN, 8.5 8.5 8.5 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 7 7 7 NaN, 9 9 9 NaN, 8 9 9 NaN, 8 9 9 NaN, 8 7 7 NaN, 8 8.5 8.5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    9 8 9 NaN, 9 8 9 NaN, 9 9 9 NaN, 10 10 10 NaN, 9 9 10 NaN, 9 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 7 7 7 NaN, 9 8 9 NaN, 8 10 9 NaN, 8 9 8 NaN, 9 9 9 NaN, 8.5 8.5 9.5 NaN, 8.5 8.5 8 NaN, 9.5 10 9.5 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 6 6 NaN, 7 7 7 NaN, 7 7 7 NaN, 7 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 5 5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    8 9 8 NaN, 9 9 9 NaN, 8 8 8 NaN, 9 9 9 NaN, 8 7 8 NaN, 9 10 9 NaN, 9 8.5 8.5 NaN, 9.5 9.5 9.5 NaN, 10 10 10 NaN, 9 9.3333 9.6666 NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 7 8 8 NaN, 9 9 9 NaN, 8 9 9 NaN, 10 9 10 NaN, 10 10 10 NaN, 9 9 9 NaN, 9 9.5 9.5 NaN, 10 10 10 NaN, 9.3333 9.3333 9.6666 NaN, NaN NaN NaN NaN;
    6 7 6 NaN, 5 5 5 NaN, 6 6 6 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 8 8 8 NaN, 9 8 9 NaN, 9 9 8 NaN, 7 7 7 NaN, 8 8 7 NaN, 9 8.5 8.5 NaN, 8 8.5 8 NaN, 9.5 9.5 9 NaN, 8 7.5 7.5 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 6 6 6 NaN, 6 7 7 NaN, 7 8 7 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN
];
season5_scores = [season5_scores; NaN(5,44)];

% ===================== Season 6 =====================
season6_names = {
    "Cristian de la Fuente"
    "Steve Guttenberg"
    "Priscilla Presley"
    "Marlee Matlin"
    "Shannon Elizabeth"
    "Marissa Jaret Winokur"
    "Jason Taylor"
    "Kristi Yamaguchi"
    "Monica Seles"
    "Penn Jillette"
    "Adam Carolla"
    "Mario"
};

season6_scores = [
    7 7 7 NaN, 7 6 7 NaN, 8 8 9 NaN, 9 8 9 NaN, 7 8 8 NaN, 9 9 9 NaN, 7.5 7.5 8 NaN, 10 9 9.5 NaN, 9.5 9 9.5 NaN, 9 8 9 NaN, NaN NaN NaN NaN;
    6 6 6 NaN, 6 5 5 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 7 7 7 NaN, 8 9 9 NaN, 7 7 8 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 8 NaN, 8 8 8 NaN, 7 7 7 NaN, 8 8 8 NaN, 7 7 8 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7 NaN, 8 8 8 NaN, 8 8 8 NaN, 9 10 9 NaN, 8 8 7 NaN, 8 8 8 NaN, 8.5 8.5 8.5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 6 6 NaN, 7 7 7 NaN, 6 7 6 NaN, 8 8 8 NaN, 8 8 8 NaN, 9 8 9 NaN, 9 8.5 8.5 NaN, 8.5 8 8.5 NaN, 8.5 9 8.5 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 8 7 NaN, 9 9 9 NaN, 8 7 8 NaN, 10 9 10 NaN, 9 9 9 NaN, 8 8 8 NaN, 9.5 8.5 9.5 NaN, 9 8 9 NaN, 9 9.5 9 NaN, 9.5 9.5 9.5 NaN, NaN NaN NaN NaN;
    9 9 9 NaN, 9 9 9 NaN, 9 9 9 NaN, 10 9 10 NaN, 9 10 10 NaN, 10 10 10 NaN, 9.5 8 9.5 NaN, 8.5 9.5 9.5 NaN, 9.5 9 10 NaN, 10 10 10 NaN, NaN NaN NaN NaN;
    5 5 5 NaN, 5 5 5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    5 6 5 NaN, 6 6 5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    5 5 5 NaN, 6 7 6 NaN, 7 7 7 NaN, 6 7 6 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    8 8 8 NaN, 9 8 9 NaN, 7 6 8 NaN, 8 7 9 NaN, 9 9 9 NaN, 9 9 10 NaN, 8.5 8.5 8.5 NaN, 9 8.5 9 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN
];
season6_scores = [season6_scores; NaN(5,44)];

% ===================== Season 7 =====================
season7_names = {
    "Ted McGinley"
    "Cloris Leachman"
    "Susan Lucci"
    "Cody Linley"
};
%% Season 7
season7_names = {
    "Ted McGinley"
    "Cloris Leachman"
    "Susan Lucci"
    "Cody Linley"
    "Misty May-Treanor"
    "Maurice Greene"
    "Warren Sapp"
    "Jeffrey Ross"
    "Toni Braxton"
    "Lance Bass"
    "Kim Kardashian"
    "Rocco DiSpirito"
    "Brooke Burke"
};

season7_scores = [
    6 6 6.5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 5 5 NaN, 5 5 5 NaN, 6 5 5 NaN, 8 7 7 NaN, 7 7 7 NaN, 5 5 5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 6 6.5 NaN, 7 7 7 NaN, 7 7 7 NaN, 8 8 8 NaN, 7 7 8 NaN, 8 8 7 NaN, 8 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 6.5 7 NaN, 7 7 7 NaN, 7 7 7 NaN, 7 8 8 NaN, 10 9 9 NaN, 8 8 7 NaN, 8 7 7 NaN, 8 8 8 NaN, 8 7.5 7.5 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6.5 7.5 7 NaN, 7 7 7 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6.5 6.5 6.5 NaN, 7 6 6 NaN, 8 8 8 NaN, 6 7 7 NaN, 9 9 9 NaN, 7 7 7 NaN, 8 9 8 NaN, 8 8 8 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7 7 7.5 NaN, 8 8 8 NaN, 9 8 8 NaN, 8 7 7 NaN, 8 8 9 NaN, 8 9 8 NaN, 7 7 7 NaN, 9.5 8.5 9 NaN, 8.5 8 8 NaN, 9 9.5 9 NaN, NaN NaN NaN NaN;
    4 4 4 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7.5 7 8 NaN, 7 8 8 NaN, 8 7 7 NaN, 7 7 8 NaN, 7 7 8 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    7.5 6 8 NaN, 7 6 7 NaN, 8 7 7 NaN, 9 8 9 NaN, 7 7 7 NaN, 9 9 9 NaN, 9 7 9 NaN, 8.5 7.5 9 NaN, 10 9 9.5 NaN, 9 9 9.5 NaN, NaN NaN NaN NaN;
    6 6.5 6 NaN, 6 6 5 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    6 5.5 6 NaN, 5 6 5 NaN, 7 7 6 NaN, 6 6 6 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, 0 0 0 NaN, NaN NaN NaN NaN;
    8 8 8.5 NaN, 8 8 8 NaN, 9 10 9 NaN, 9 8 9 NaN, 10 9 10 NaN, 8 10 8 NaN, 10 10 10 NaN, 9.5 8.5 9.5 NaN, 8 8.5 8 NaN, 10 10 10 NaN, NaN NaN NaN NaN
];
% ====== 预留空行（未实际添加），用于后续数据处理 ======
global senior_coupon
global senior_shortfall
global senior_bal
global mezz_coupon
global mezz_shortfall
global mezz_bal
global junior_coupon
global junior_shortfall
global junior_bal
global subordinate_coupon
global subordinate_shortfall
global subordinate_percent
global subordinate_bal
global type
global duration
global recovery
global equity_bal
global transMatPIT
global trials
global sponsor_bal
global sponsor_management_fee
global sponsor_shortfall

type = 5;
trials = 1000;
duration = 10;
sponsor_management_fee = 0.1;
sponsor_incentive_fee = 10;
equity_percent = 4.5;
subordinate_percent = 4;
junior_percent = 1;
mezz_percent = 1;
senior_percent = 89.5;
recovery = 0.4;
       
coupons = [0.0134    % AAA
           0.0141    % AA
           0.0151    % A
           0.0231    % BBB
           0.0380    % BB
           0.0554    % B
           0.1242    % CCC
           0     ];  % D

senior_losses = 0;
mezz_losses = 0;
junior_losses = 0;
subordinate_losses = 0;
equity_losses = 0;
equity_total_bal = 0;
sponsor_total_bal = 0;
sponsor_total_incentive_fee = 0;

load Data_TransProb
prepData = transprobprep(data);

Years = 1983:2004;
nYears = length(Years);
nRatings = length(prepData.ratingsLabels);
transMatPIT = zeros(nRatings,nRatings,nYears);
algorithm = 'duration';
sampleTotals(nYears,1) = struct('totalsVec',[],'totalsMat',[],...
'algorithm',algorithm);
for t = 1:nYears
   startDate = ['31-Dec-' num2str(Years(t)-1)];
   endDate = ['31-Dec-' num2str(Years(t))];
   [transMatPIT(:,:,t),sampleTotals(t)] = transprob(prepData,...
    'startDate',startDate,'endDate',endDate,'algorithm',algorithm);

end

for x = 1:trials

    msize = size(transMatPIT, 3);

    port = [0; 0; 0; 0; 0; 0; 0; 0];
    port(type) = 100;
    
    sponsor_bal = 0;
    sponsor_shortfall = 0;
    equity_bal = 0;
    subordinate_bal = 0;
    subordinate_shortfall = 0;
    subordinate_coupon = subordinate_percent * coupons(7);
    junior_bal = 0;
    junior_shortfall = 0;
    junior_coupon = junior_percent * coupons(5);
    mezz_bal = 0;
    mezz_shortfall = 0;
    mezz_coupon = mezz_percent * coupons(4);
    senior_bal = 0;
    senior_shortfall = 0;
    senior_coupon = senior_percent * coupons(1);
    coupon = sum(port .* coupons) / sum(port);

    for d = 1:duration
        ctm = transMatPIT(:, :, randi(msize))' / 100;
        port = ctm * port;
        defaults = port(8);
        port(8) = 0;
        port(type) = port(type) + recovery*defaults;
        waterfall(sum(port)*coupon);
    end
    
    senior_shortfall = senior_shortfall + senior_percent;
    mezz_shortfall = mezz_shortfall + mezz_percent;
    junior_shortfall = junior_shortfall + junior_percent;
    subordinate_shortfall = subordinate_shortfall + subordinate_percent;
    
    losses = 100 - sum(port);
    
    equity_cashflow = min(losses, equity_percent);
    equity_losses = equity_losses + equity_cashflow;
    losses = losses - equity_cashflow;
    
    subordinate_cashflow = min(losses, subordinate_percent);
    subordinate_losses = subordinate_losses + subordinate_cashflow;
    losses = losses - subordinate_cashflow;
    
    junior_cashflow = min(losses, junior_percent);
    junior_losses = junior_losses + junior_cashflow;
    losses = losses - junior_cashflow;
    
    mezz_cashflow = min(losses, mezz_percent);
    mezz_losses = mezz_losses + mezz_cashflow;
    losses = losses - mezz_cashflow;
    
    senior_losses = senior_losses + losses;
    losses = 0;
    
    waterfall(sum(port));
    port = [0; 0; 0; 0; 0; 0; 0; 0];
    equity_total_bal = equity_total_bal + equity_bal;
    incentive_fee = max(0,(equity_bal - equity_percent) * (sponsor_incentive_fee / 100));
    sponsor_total_incentive_fee = sponsor_total_incentive_fee + incentive_fee;
    equity_total_bal = equity_total_bal - incentive_fee;
    sponsor_bal = sponsor_bal + incentive_fee;
    sponsor_total_bal = sponsor_total_bal + sponsor_bal;
end

senior_losses = (senior_losses / (senior_percent / 100)) / trials;
mezz_losses = (mezz_losses / (mezz_percent / 100)) / trials;
junior_losses = (junior_losses / (junior_percent / 100)) / trials;
subordinate_losses = (subordinate_losses / (subordinate_percent / 100)) / trials;
equity_losses = (equity_losses / (equity_percent / 100)) / trials;

sponsor_avg_fee = sponsor_total_bal / trials;
sponsor_annual_fee = sponsor_avg_fee / duration;
sponsor_avg_incentive_fee = sponsor_total_incentive_fee / trials;
sponsor_annual_incentive_fee = sponsor_avg_incentive_fee / duration;
sponsor_annual_management_fee = min(sponsor_management_fee, sponsor_annual_fee);
equity_avg_val = equity_total_bal / trials;
net_equity_returns = ((equity_avg_val - equity_percent) / 30);
gross_equity_returns = net_equity_returns + sponsor_annual_fee;
equity_returns = net_equity_returns / (equity_percent / 100);


senior_losses = round(senior_losses, 2);
mezz_losses = round(mezz_losses, 2);
junior_losses = round(junior_losses, 2);
subordinate_losses = round(subordinate_losses, 2);
equity_returns = round(equity_returns, 2);
sponsor_annual_fee = round (sponsor_annual_fee, 2);
sponsor_annual_management_fee = round(sponsor_annual_management_fee, 2);
sponsor_annual_incentive_fee = round(sponsor_annual_incentive_fee, 2);
net_equity_returns = round(net_equity_returns, 2);
gross_equity_returns = round(gross_equity_returns, 2);

if (senior_percent > 0)
    disp("Senior tranche losses were " + senior_losses + "%");
    disp("The senior tranche is rated " + rate(senior_losses));
end

if (mezz_percent > 0)
    disp("Mezzanine tranche losses were " + mezz_losses + "%");
    disp("The mezzanine tranche is rated " + rate(mezz_losses));
end

if (junior_percent > 0)
    disp("Junior tranche losses were " + junior_losses + "%");
    disp("The junior tranche is rated " + rate(junior_losses));
end

if (subordinate_percent > 0)
    disp("Subordinate tranche losses were " + subordinate_losses + "%");
    disp("The subordinate tranche is rated " + rate(subordinate_losses));
end

disp("The equity average annual returns are " + equity_returns + "% per year");
if (sponsor_annual_fee ~= 0)
    disp("The average annual fees are " + sponsor_annual_fee + "% per year");
    disp("This is " + round((sponsor_annual_fee / (equity_percent / 100)), 2) + "% of the equity per year");
    if ((equity_returns + sponsor_annual_fee) ~= 0)
        disp("Which is " + round(((sponsor_annual_fee / gross_equity_returns) * 100), 2) + "% of the gross equity returns");
    else
        disp("Which is Inf% of the gross equity returns");
    end
    if (equity_returns ~= 0)
        disp("Or " + round(((sponsor_annual_fee / net_equity_returns) * 100), 2) + "% of the net equity returns");
    else
        disp("Or Inf% of the net equity returns");
    end
    disp("Fees include Management and Incentive Fees");
    disp("The annual management fees are " + sponsor_annual_management_fee + "% per year");
    disp("This is " + round((sponsor_annual_management_fee / (equity_percent / 100)), 2) + "% of the equity per year");
    if ((equity_returns + sponsor_annual_fee) ~= 0)
        disp("Which is " + round(((sponsor_annual_management_fee / gross_equity_returns) * 100), 2) + "% of the gross equity returns");
    else
        disp("Which is Inf% of the gross equity returns");
    end
    if (equity_returns ~= 0)
        disp("Or " + round(((sponsor_annual_management_fee / net_equity_returns) * 100), 2) + "% of the net equity returns");
    else
        disp("Or Inf% of the net equity returns");
    end
    disp("The annual incentive fees are " + sponsor_annual_incentive_fee + "% per year");
    disp("This is " + round((sponsor_annual_incentive_fee / (equity_percent / 100)), 2) + "% of the equity per year");
    if ((equity_returns + sponsor_annual_fee) ~= 0)
        disp("Which is " + round(((sponsor_annual_incentive_fee / gross_equity_returns) * 100), 2) + "% of the gross equity returns");
    else
        disp("Which is Inf% of the gross equity returns");
    end
    if (equity_returns ~= 0)
        disp("Or " + round(((sponsor_annual_incentive_fee / net_equity_returns) * 100), 2) + "% of the net equity returns");
    else
        disp("Or Inf% of the net equity returns");
    end
end

function waterfall(cashflow)
    global senior_coupon
    global senior_shortfall
    global senior_bal
    global mezz_coupon
    global mezz_shortfall
    global mezz_bal
    global junior_coupon
    global junior_shortfall
    global junior_bal
    global subordinate_coupon
    global subordinate_shortfall
    global subordinate_bal
    global equity_bal
    global sponsor_bal
    global sponsor_management_fee
    global sponsor_shortfall
    
    cashflow = cashflow + equity_bal;
    equity_bal = 0;
    
    sponsor_cashflow = min(cashflow, (sponsor_management_fee + sponsor_shortfall));
    sponsor_bal = sponsor_bal + sponsor_cashflow;
    sponsor_shortfall = sponsor_shortfall + sponsor_management_fee - sponsor_cashflow;
    cashflow = cashflow - sponsor_cashflow;
    
    senior_cashflow = min(cashflow, (senior_coupon + senior_shortfall));
    senior_shortfall = senior_shortfall + senior_coupon - senior_cashflow;
    senior_bal = senior_bal + senior_cashflow;
    cashflow = cashflow - senior_cashflow;

    mezz_cashflow = min(cashflow, (mezz_coupon + mezz_shortfall));
    mezz_shortfall = mezz_shortfall + mezz_coupon - mezz_cashflow;
    mezz_bal = mezz_bal + mezz_cashflow;
    cashflow = cashflow - mezz_cashflow;

    junior_cashflow = min(cashflow, (junior_coupon + junior_shortfall));
    junior_shortfall = junior_shortfall + junior_coupon - junior_cashflow;
    junior_bal = junior_bal + junior_cashflow;
    cashflow = cashflow - junior_cashflow;

    subordinate_cashflow = min(cashflow, (subordinate_coupon + subordinate_shortfall));
    subordinate_shortfall = subordinate_shortfall + subordinate_coupon - subordinate_cashflow;
    subordinate_bal = subordinate_bal + subordinate_cashflow;
    cashflow = cashflow - subordinate_cashflow;
    
    equity_bal = equity_bal + cashflow;
      
end

function rating=rate(credit_losses)
    global recovery
    global transMatPIT
    global trials
    global type
    global duration
    
    msize = size(transMatPIT, 3);
    losses = zeros(8,1);
    
    for x = 1:trials
        for y = 1:8
            port = [0;0;0;0;0;0;0;0];
            port(y) = 100;
            for z = 1:duration
                ctm = transMatPIT(:, :, randi(msize))' / 100;
                port = ctm * port;
                defaults = port(8);
                port(8) = 0;
                port(type) = port(type) + recovery*defaults;    
            end
            losses(y) = losses(y) + 100-sum(port);
            
        end
        
    end
    
    losses = losses / 1000;
    losses = losses * 1.1; % Give margin of safety 
                           % so ratings are consistent
    
    if (credit_losses <= (losses(1)))
        rating = "AAA";
    elseif (credit_losses <= (losses(2)))
        rating = "AA";
    elseif (credit_losses <= (losses(3)))
        rating = "A";
    elseif (credit_losses <= (losses(4)))
        rating = "BBB";
    elseif (credit_losses <= (losses(5)))
        rating = "BB";
    elseif (credit_losses <= (losses(6)))
        rating = "B";
    elseif (credit_losses <= (losses(7)))
        rating = "CCC";
    else
        rating = "D";
    end 
end
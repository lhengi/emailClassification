
alpha = 0.1;

fid = fopen('SMSSpamCollection');            % read file
data = fread(fid);
fclose(fid);
lcase = abs('a'):abs('z');
ucase = abs('A'):abs('Z');
caseDiff = abs('a') - abs('A');
caps = ismember(data,ucase);
data(caps) = data(caps)+caseDiff;     % convert to lowercase
data(data == 9) = abs(' ');          % convert tabs to spaces
validSet = [9 10 abs(' ') lcase];         
data = data(ismember(data,validSet)); % remove non-space, non-tab, non-(a-z) characters
data = char(data);                    % convert from vector to characters

words = strsplit(data');             % split into words

% split into examples
count = 0;
examples = {};

for (i=1:length(words))
   if (strcmp(words{i}, 'spam') || strcmp(words{i}, 'ham'))
       count = count+1;
       examples(count).spam = strcmp(words{i}, 'spam');
       examples(count).words = [];
   else
       examples(count).words{length(examples(count).words)+1} = words{i};
   end
end

%split into training and test
random_order = randperm(length(examples));
train_examples = examples(random_order(1:floor(length(examples)*.8)));
test_examples = examples(random_order(floor(length(examples)*.8)+1:end));

% count occurences for spam and ham

for i = -5:0
    [spamcounts(i+6), numspamwords(i+6), hamcounts(i+6), numhamwords(i+6), spamP(i+6),hamP(i+6)] = trainData(2^i,train_examples);
    [trainFscore(i+6), trainAccuracy(i+6),trainPre(i+6)] = myFunction(2^i,train_examples,spamcounts(i+6),hamcounts(i+6),numhamwords(i+6), numspamwords(i+6), spamP(i+6), hamP(i+6));
    [testFscore(i+6), testAccuracy(i+6),testPre(i+6)] = myFunction(2^i,test_examples,spamcounts(i+6),hamcounts(i+6),numhamwords(i+6), numspamwords(i+6), spamP(i+6), hamP(i+6));
    %spamcounts(i+6).get('free')/(numspamwords(i+6)+(2^i)*20000);   % probability of word 'free' given spam
    %hamcounts(i+6).get('free')/(numhamwords(i+6)+(2^i)*20000) ;  % probability of word 'free' given ham
end

% will need to check if count is empty!
                 
x = -5:0
figure(1);
plot(x,testFscore);
hold on;
plot(x,trainFscore);
legend('test f-score','train f-score');
xlabel('i');
ylabel('f-scores');
hold off;
                 
figure(2);
plot(x,testAccuracy)
hold on;
plot(x,trainAccuracy)
legend('test Accuracy', 'train Accuracy');
xlabel('i')
ylabel('Accuracy')
hold off;
                 
disp(testPre);      


function [spamcounts, numspamwords, hamcounts, numhamwords, spamP, hamP] = trainData(alpha,train_examples)
% train with a specific alpha
                 
    spamcounts = javaObject('java.util.HashMap');
    numspamwords = 0;
    hamcounts = javaObject('java.util.HashMap');
    numhamwords = 0;
    spamP = 0;
    hamP = 0;
    for (i=1:length(train_examples))
        if (train_examples(i).spam == 1)
            spamP = spamP + 1;
        else
            hamP = hamP + 1;
        end
        for (j=1:length(train_examples(i).words))
            word = train_examples(i).words{j};
            if (train_examples(i).spam == 1)
                numspamwords = numspamwords+1;
                current_count = spamcounts.get(word);
                if(isempty(current_count))
                    spamcounts.put(word, 1+alpha);    % initialize by including pseudo-count prior
                else
                    spamcounts.put(word, current_count+1);  % increment
                end
            else
                 numhamwords = numhamwords+1;
                 current_count = hamcounts.get(word);
                if (isempty(current_count))
                     hamcounts.put(word, 1+alpha);    % initialize by including pseudo-count prior
                else
                     hamcounts.put(word, current_count+1);  % increment
                end
            end
        end
    end
    spamP = spamP/length(train_examples);
    hamP = hamP/length(train_examples);
end
                 

function [fScore,accuracy, precision] = myFunction(alpha, test_examples, spamcounts, hamcounts, numhamwords, numspamwords, spamP,hamP)
    positive = 0;
    negative = 0;
    falsePos = 0;
    falseNeg = 0;

    for (i=1: length(test_examples))
        currentSpamP = 1;
        currentHamP = 1;
        for(j=1:length(test_examples(i).words))
            word = test_examples(i).words{j};
            if (spamcounts.get(word) ~= 0)
                currentSpamP = currentSpamP * (spamcounts.get(word)/(numspamwords+alpha*20000));
            else
                currentSpamP = currentSpamP * (alpha/(numspamwords+alpha*20000));
            end
            
            if (hamcounts.get(word) ~= 0)
                currentHamP = currentHamP *(hamcounts.get(word)/(numhamwords+alpha*20000));
            else
                currentHamP = currentHamP * (alpha/(numhamwords+alpha*20000));
            end
        % currentSpamP *= the probalility of being spam which is( the number of
        % spam email in testexample/ length(test_examples)
        end
        
        currentSpamP = currentSpamP * spamP;
        currentHamP = currentHamP * hamP;
                                                        
        if (test_examples(i).spam == 1 & currentSpamP > currentHamP)
            positive = positive + 1;
        elseif(test_examples(i).spam ~= 1 & currentSpamP > currentHamP)
            falsePos = falsePos + 1;
        end
        
        if (test_examples(i).spam == 0 & currentHamP > currentSpamP)
            negative = negative + 1;
        elseif(test_examples(i).spam ~= 0 & currentHamP > currentSpamP)
            falseNeg = falseNeg + 1;
        end
        
    end
            
    alpha
    accuracy = ((negative+positive)/length(test_examples))*100
    precision = positive/(positive + falsePos)
    
    recall = positive/(positive + falseNeg)
    fScore = 2*((precision*recall)/(precision + recall))
    display(length(test_examples));

end
                                                             
% ... 

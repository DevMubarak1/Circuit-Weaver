@echo off
echo Updating Git Repository...

:: Add all changes
git add .

:: Get current date and time for commit message
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set commit_date=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%
set commit_time=%datetime:~8,2%:%datetime:~10,2%

:: Commit changes with timestamp
git commit -m "Update %commit_date% %commit_time%"

:: Push to remote repository
git push origin main

echo Git Update Complete! 
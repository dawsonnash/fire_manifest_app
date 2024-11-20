# fire_app

Load Calculator/Trip Preference Algorithm

## Fixes and Considerations Needed

1. Error Check: If no crewmembers are on a load, just gear items
2. Error Check: If a crewmember or gear item (individual or grouping) weight is greater than max load weight
3. Error Flag: For those not placed into loads after final sort. Backtrack and re-run?
    a. Potential Fix: greedy balancing/backtracking algorithm where it finds lightest load and places there
4. Consideration: Are break statements needed for every case?
This contains a few scripts that I wrote to make it easier to do some basic data exploration and visualization from the command line.

For example, suppose you are training an RL agent using [RLlib](https://github.com/ray-project/ray/tree/master/rllib). If you want to generate some of your own plots from the results.json file (stored in `~/ray_results` by default), you can simply run a command like below (assuming you have jq installed):

```
cat result.json | jq '.episode_reward_mean' | plot -t 'Training Reward' -x 'Training Iteration' -y 'Episode Reward Mean' -c
```

This also contains other utilities like `count-to-dist` which is used to convert counts (like those output from `uniq -c`) into a distribution. As a trivial example, we can get the distribution of whitespace lines vs meaningful lines in the `plot` script as follows:

```
cat plot | sed 's/^[^\s].*/NOT_WHITESPACE/' | sort | uniq -c | ./count-to-dist
```

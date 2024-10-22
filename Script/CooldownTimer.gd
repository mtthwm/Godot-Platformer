class_name  CooldownTimer extends Object

var _cooldownTime = 0.25;
var _available = true;
var _time_elapsed = 0;

func is_available ():
    return _available;

func get_percent ():
    if _available:
        return 1;
    else:
        return _time_elapsed / _cooldownTime;

func use ():
    _available = false;
    _time_elapsed = 0;

func run_timer (timeDelta):
    if !_available:
        _time_elapsed += timeDelta;
        if _time_elapsed >= _cooldownTime:
            _available = true;

func _init (cooldownTime):
    _cooldownTime = cooldownTime;
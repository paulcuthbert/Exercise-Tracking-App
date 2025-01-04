import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Clock, CheckCircle, PlusCircle, XCircle, BarChart2 } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

const ExerciseTracker = () => {
  const initialExercises = [
    { name: 'Squats', lastCompleted: null, history: [] },
    { name: 'Deadlifts', lastCompleted: null, history: [] },
    { name: 'Bench Press', lastCompleted: null, history: [] },
    { name: 'Pull-ups', lastCompleted: null, history: [] },
    { name: 'Overhead Press', lastCompleted: null, history: [] }
  ];

  // State management
  const [exercises, setExercises] = useState(() => {
    const saved = localStorage.getItem('exercises');
    return saved ? JSON.parse(saved) : initialExercises;
  });
  const [newExerciseName, setNewExerciseName] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [showStats, setShowStats] = useState(false);
  const [selectedExercise, setSelectedExercise] = useState(null);
  const [workoutDetails, setWorkoutDetails] = useState({ sets: '', reps: '', weight: '' });
  const [showWorkoutDialog, setShowWorkoutDialog] = useState(false);

  // Save to localStorage whenever exercises change
  useEffect(() => {
    localStorage.setItem('exercises', JSON.stringify(exercises));
  }, [exercises]);

  const getDaysSince = (date) => {
    if (!date) return Infinity;
    const diff = new Date() - new Date(date);
    return Math.floor(diff / (1000 * 60 * 60 * 24));
  };

  const handleWorkoutSubmit = () => {
    const workout = {
      date: new Date().toISOString(),
      sets: parseInt(workoutDetails.sets),
      reps: parseInt(workoutDetails.reps),
      weight: parseFloat(workoutDetails.weight)
    };

    setExercises(exercises.map(exercise => 
      exercise.name === selectedExercise 
        ? { 
            ...exercise, 
            lastCompleted: workout.date,
            history: [...(exercise.history || []), workout]
          }
        : exercise
    ));

    setShowWorkoutDialog(false);
    setWorkoutDetails({ sets: '', reps: '', weight: '' });
    setSelectedExercise(null);
  };

  const markCompleted = (exerciseName) => {
    setSelectedExercise(exerciseName);
    setShowWorkoutDialog(true);
  };

  const addExercise = () => {
    if (newExerciseName.trim()) {
      setExercises([...exercises, { 
        name: newExerciseName.trim(), 
        lastCompleted: null,
        history: []
      }]);
      setNewExerciseName('');
      setShowAddForm(false);
    }
  };

  const removeExercise = (exerciseName) => {
    setExercises(exercises.filter(ex => ex.name !== exerciseName));
  };

  const getLastCompletedText = (date) => {
    if (!date) return "Never completed";
    const days = getDaysSince(date);
    return days === 0 ? "Completed today" 
         : days === 1 ? "1 day since completed"
         : `${days} days since completed`;
  };

  const getCompletionStats = () => {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.setDate(now.getDate() - 30));
    
    return exercises.map(exercise => {
      const completions = (exercise.history || [])
        .filter(workout => new Date(workout.date) > thirtyDaysAgo)
        .length;
      
      return {
        name: exercise.name,
        completions,
        daysSinceLastCompleted: getDaysSince(exercise.lastCompleted) || 30
      };
    });
  };

  const sortedExercises = [...exercises].sort((a, b) => 
    getDaysSince(a.lastCompleted) < getDaysSince(b.lastCompleted) ? 1 : -1
  );

  return (
    <Card className="w-full max-w-4xl">
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Clock className="w-6 h-6" />
            Exercise Tracker
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setShowStats(!showStats)}
              className="flex items-center gap-2"
            >
              <BarChart2 className="w-4 h-4" />
              {showStats ? 'Hide Stats' : 'Show Stats'}
            </Button>
            <Button
              onClick={() => setShowAddForm(!showAddForm)}
              className="flex items-center gap-2"
            >
              <PlusCircle className="w-4 h-4" />
              Add Exercise
            </Button>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        {showAddForm && (
          <div className="mb-6 p-4 bg-gray-100 rounded-lg space-y-4">
            <Input
              placeholder="Exercise name"
              value={newExerciseName}
              onChange={(e) => setNewExerciseName(e.target.value)}
            />
            <Button onClick={addExercise}>Add Exercise</Button>
          </div>
        )}

        {showStats && (
          <div className="mb-6 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={getCompletionStats()}>
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Line type="monotone" dataKey="completions" stroke="#2563eb" name="30-day completions" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}

        <div className="space-y-4">
          {sortedExercises.length === 0 ? (
            <Alert>
              <AlertDescription>
                No exercises found. Try adding some exercises!
              </AlertDescription>
            </Alert>
          ) : (
            sortedExercises.map((exercise) => (
              <div 
                key={exercise.name}
                className="flex items-center justify-between p-3 rounded-lg bg-gray-100 hover:bg-gray-200 transition-colors"
              >
                <div className="space-y-1">
                  <div className="font-medium">{exercise.name}</div>
                  <div className="text-sm text-gray-600">
                    {getLastCompletedText(exercise.lastCompleted)}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Button 
                    onClick={() => markCompleted(exercise.name)}
                    className="flex items-center gap-2"
                  >
                    <CheckCircle className="w-4 h-4" />
                    Mark Complete
                  </Button>
                  <Button 
                    variant="ghost"
                    onClick={() => removeExercise(exercise.name)}
                    className="text-red-500 hover:text-red-700 p-2"
                  >
                    <XCircle className="w-5 h-5" />
                  </Button>
                </div>
              </div>
            ))
          )}
        </div>

        <Dialog open={showWorkoutDialog} onOpenChange={setShowWorkoutDialog}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Log Workout Details - {selectedExercise}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div>
                <Input
                  type="number"
                  placeholder="Number of sets"
                  value={workoutDetails.sets}
                  onChange={(e) => setWorkoutDetails({...workoutDetails, sets: e.target.value})}
                />
              </div>
              <div>
                <Input
                  type="number"
                  placeholder="Reps per set"
                  value={workoutDetails.reps}
                  onChange={(e) => setWorkoutDetails({...workoutDetails, reps: e.target.value})}
                />
              </div>
              <div>
                <Input
                  type="number"
                  placeholder="Weight (lbs)"
                  value={workoutDetails.weight}
                  onChange={(e) => setWorkoutDetails({...workoutDetails, weight: e.target.value})}
                />
              </div>
              <Button onClick={handleWorkoutSubmit} className="w-full">
                Save Workout
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </CardContent>
    </Card>
  );
};

export default ExerciseTracker;

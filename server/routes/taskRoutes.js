const express = require('express');
const {
  listTasks,
  getTask,
  getTaskMeta,
  getTaskAssignees,
  createTaskHandler,
  updateTaskHandler,
  updateTaskStatusHandler,
  addTaskNoteHandler,
  deleteTaskHandler,
} = require('../controllers/taskController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authenticate);

router.get('/meta/options', checkRole(['Admin', 'Supervisor']), getTaskMeta);
router.get('/meta/assignees', checkRole(['Admin', 'Supervisor']), getTaskAssignees);
router.get('/', listTasks);
router.get('/:id', getTask);
router.post('/', checkRole(['Admin', 'Supervisor']), createTaskHandler);
router.patch('/:id/status', updateTaskStatusHandler);
router.post('/:id/notes', authenticate, addTaskNoteHandler);
router.patch('/:id', checkRole(['Admin', 'Supervisor']), updateTaskHandler);
router.delete('/:id', checkRole(['Admin']), deleteTaskHandler);

module.exports = router;

//
// Copyright 2010, Darren Lafreniere
// <http://www.lafarren.com/theseus-minotaur-solver/>
// 
// This file is part of lafarren.com's Theseus and Minotaur Maze Solver,
// or tmmaze-solver.
// 
// tmmaze-solver is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// tmmaze-solver is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with tmmaze-solver, named License.txt. If not, see
// <http://www.gnu.org/licenses/>.
//
package com.lafarren.tmmaze.controller
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import mx.core.Application;
	
	import com.lafarren.tmmaze.core.EntityType;
	import com.lafarren.tmmaze.core.Controller;
	import com.lafarren.tmmaze.core.Game;
	import com.lafarren.tmmaze.core.GameEvent;
	import com.lafarren.tmmaze.core.MoveType;
	import com.lafarren.tmmaze.solver.Solver;
	
	/**
	 * Dispatched when Theseus begins a solver execution.
	 *
	 * @eventType com.lafarren.tmmaze.controller.TheseusUserEvent.SOLVER_BEGIN
	 */
	[Event(name = "solverBegin", type = "com.lafarren.tmmaze.controller.TheseusUserEvent.SOLVER_BEGIN")]
	
	/**
	 * Dispatched when Theseus end a solver execution.
	 *
	 * @eventType com.lafarren.tmmaze.controller.TheseusUserEvent.SOLVER_END
	 */
	[Event(name = "solverEnd", type = "com.lafarren.tmmaze.controller.TheseusUserEvent.SOLVER_END")]
	
	/**
	 * Dispatched when Theseus's solver solution changes.
	 *
	 * @eventType com.lafarren.tmmaze.controller.TheseusUserEvent.SOLVER_SOLUTION_CHANGE
	 */
	[Event(name = "solverSolutionChange", type = "com.lafarren.tmmaze.controller.TheseusUserEvent.SOLVER_SOLUTION_CHANGE")]
	
	/**
	 * Implements a user operated Theseus controller. Supports keyboard
	 * navigation.
	 */
	public class TheseusUser extends EventDispatcher implements Controller
	{
		public static const SOLVER_TIME_SLICE_SECONDS:Number = 1.0 / 30.0;
		
		private var m_game:Game;
		
		private var m_solverEnabled:Boolean;
		private var m_autoComplete:Boolean;
		private var m_solver:Solver;
		private var m_solutionPath:Vector.<MoveType>;
		
		// Stack of keys that are currently down.
		private var m_keyStack:Vector.<uint>;
		
		/**
		 * Constructors a TheseusUser instance to control Theseus in the specified
		 * Game.
		 */
		public function TheseusUser(game:Game)
		{
			m_game = game;
			setSolutionPathUndetermined();
			
			m_keyStack = new Vector.<uint>();
			
			m_game.addEventListener(GameEvent.BEGIN, onGameBegin);
			Application.application.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Application.application.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			Application.application.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		}
		
		/**
		 * Destroys this controller and its members.
		 */
		public function destroy():void
		{
			m_game.removeEventListener(GameEvent.BEGIN, onGameBegin);
			Application.application.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			solveEnd();
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone(game:Game = null):Controller
		{
			// Not supported
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get agent():EntityType
		{
			return EntityType.THESEUS;
		}
		
		/**
		 * @inheritDoc
		 */
		public function determineMoveType():MoveType
		{
			var result:MoveType = null;
			
			// If auto-complete is enabled and we have a valid solution path,
			// use the next move in it and ignore the user's input.
			if (this.autoComplete && this.solverSucceeded)
			{
				result = this.solutionPathNextMove;
			}
			else if (m_keyStack.length > 0)
			{
				result = keycodeToMoveType(m_keyStack[m_keyStack.length - 1]);
			}
			
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		public function onMoved(moveType:MoveType):void
		{
			if (m_solverEnabled)
			{
				if (moveType == this.solutionPathNextMove)
				{
					m_solutionPath.splice(0, 1);
					dispatchEvent(TheseusUserEvent.solverSolutionChange(this, m_game));
				}
				else
				{
					solveBegin();
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function onMoveFailed(moveType:MoveType):void
		{
		}
		
		/**
		 * If true, the solver is executed as needed to find a solution.
		 */
		public function get solverEnabled():Boolean
		{
			return m_solverEnabled;
		}
		
		public function set solverEnabled(solverEnabled:Boolean):void
		{
			if (m_solverEnabled != solverEnabled)
			{
				m_solverEnabled = solverEnabled;
				if (m_solverEnabled && m_game.began)
				{
					solveBegin();
				}
				else
				{
					solveEnd();
					
					if (!this.solverFailed)
					{
						setSolutionPathUndetermined();
					}
				}
			}
		}
		
		/**
		 * If true and a valid solution path has been found, keyboard control
		 * will be ignored and the controller will automatically navigate the
		 * solution path.
		 */
		public function get autoComplete():Boolean
		{
			return m_autoComplete;
		}
		
		public function set autoComplete(autoComplete:Boolean):void
		{
			m_autoComplete = autoComplete;
		}
		
		/**
		 * The solution path if the solver is enabled. If the solver is
		 * enabled and this is null, then no solution could be found. If the
		 * solver is enabled and this is an empty vector, then either either
		 * Theseus has won, or the solver is still evaluating.
		 */
		public function get solutionPath():Vector.<MoveType>
		{
			return m_solutionPath;
		}
		
		/**
		 * The next move of the solution path, or null if there is no next move.
		 */
		public function get solutionPathNextMove():MoveType
		{
			return (m_solutionPath && m_solutionPath.length > 0) ? m_solutionPath[0] : null;
		}
		
		/**
		 * True if the solver is currently running.
		 */
		public function get solving():Boolean
		{
			return m_solver != null;
		}
		
		/**
		 * True if the solver has found a solution.
		 */
		public function get solverSucceeded():Boolean
		{
			return !this.solving && !this.solverFailed;
		}
		
		/**
		 * True if the solver has failed to find a solution.
		 */
		public function get solverFailed():Boolean
		{
			// Null implies failure.
			return m_solutionPath == null;
		}
		
		private function onGameBegin(event:GameEvent):void
		{
			if (m_solverEnabled)
			{
				solveBegin();
			}
		}
		
		private function solveBegin():void
		{
			// If the solver has already failed, it's pointless to try solving again
			if (!this.solverFailed)
			{
				setSolutionPathUndetermined();
				
				m_solver = new Solver(m_game, SOLVER_TIME_SLICE_SECONDS);
				dispatchEvent(TheseusUserEvent.solverBegin(this, m_game));
				
				Application.application.addEventListener(Event.ENTER_FRAME, solveTimeSlice);
			}
		}
		
		private function solveEnd():void
		{
			if (m_solver)
			{
				Application.application.removeEventListener(Event.ENTER_FRAME, solveTimeSlice);
				
				m_solver.destroy();
				m_solver = null;
				System.gc();
				
				dispatchEvent(TheseusUserEvent.solverEnd(this, m_game));
			}
		}
		
		private function solveTimeSlice(event:Event):void
		{
			m_solver.executeTimeSlice();
			if (m_solver.completed)
			{
				var solutionPath:Vector.<MoveType> = m_solver.solutionPath;
				solveEnd();
				setSolutionPath(solutionPath);
			}
		}
		
		private function setSolutionPathUndetermined():void
		{
			// Null implies failure, so set an empty path as a placeholder.
			setSolutionPath(new Vector.<MoveType>([]));
		}
		
		private function setSolutionPathFailed():void
		{
			// Null implies failure.
			setSolutionPath(null);
		}
		
		private function setSolutionPath(solutionPath:Vector.<MoveType>):void
		{
			m_solutionPath = solutionPath;
			dispatchEvent(TheseusUserEvent.solverSolutionChange(this, m_game));
		}
		
		private function keycodeToMoveType(keyCode:uint):MoveType
		{
			var result:MoveType = null;
			if (m_game.isCurrentAgent(this.agent))
			{
				switch (keyCode)
				{
					case Keyboard.UP:
					case "W".charCodeAt():
					{
						result = MoveType.UP;
					}
					break;
					
					case Keyboard.DOWN:
					case "S".charCodeAt():
					{
						result = MoveType.DOWN;
					}
					break;
					
					case Keyboard.LEFT:
					case "A".charCodeAt():
					{
						result = MoveType.LEFT;
					}
					break;
					
					case Keyboard.RIGHT:
					case "D".charCodeAt():
					{
						result = MoveType.RIGHT;
					}
					break;
					
					case Keyboard.SPACE:
					{
						result = MoveType.SKIP;
					}
					break;
				}
			}
			
			return result;
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			event.stopPropagation();
			keyStackRemove(event.keyCode);
			keyStackPush(event.keyCode);
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			event.stopPropagation();
			keyStackRemove(event.keyCode);
		}
		
		private function onFocusOut(event:FocusEvent):void
		{
			keyStackClear();
		}
		
		private function keyStackPush(keyCode:uint):void
		{
			m_keyStack.push(keyCode);
		}
		
		private function keyStackRemove(keyCode:uint):void
		{
			// Iterate backwards to prevent removal from affecting iteration
			for (var i:int = m_keyStack.length; --i >= 0; )
			{
				if (m_keyStack[i] == keyCode)
				{
					m_keyStack.splice(i, 1);
				}
			}
		}
		
		private function keyStackClear():void
		{
			m_keyStack.splice(0, m_keyStack.length);
		}
	}
}

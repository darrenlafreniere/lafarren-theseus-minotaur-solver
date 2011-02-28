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
	
	import com.lafarren.tmmaze.core.Game;
	
	/**
	 * Event class dispatched from a TheseusUser instance.
	 */
	public class TheseusUserEvent extends Event
	{
		/**
		 * Defines the value of the <code>type</code> property of the event object 
		 * for a <code>solverBegin</code> event.
		 *
		 * <p>The properties of the event object have the following values:</p>
		 * <table class=innertable>
		 * 		<tr><th>Property</th><th>Value</th></tr>
		 * 		<tr><td>theseusUser</td><td>The TheseusUser that dispatched this event</td></tr>
		 * 		<tr><td>game</td><td>The Game that contains the TheseusUser controller</td></tr>
		 * </table>
		 *
		 * @eventType solverBegin
		 */
		public static const SOLVER_BEGIN:String = "solverBegin";
		
		/**
		 * Defines the value of the <code>type</code> property of the event object 
		 * for a <code>solverEnd</code> event.
		 *
		 * <p>The properties of the event object have the following values:</p>
		 * <table class=innertable>
		 * 		<tr><th>Property</th><th>Value</th></tr>
		 * 		<tr><td>theseusUser</td><td>The TheseusUser that dispatched this event</td></tr>
		 * 		<tr><td>game</td><td>The Game that contains the TheseusUser controller</td></tr>
		 * </table>
		 *
		 * @eventType solverEnd
		 */
		public static const SOLVER_END:String = "solverEnd";
		
		/**
		 * Defines the value of the <code>type</code> property of the event object 
		 * for a <code>solverSolutionChange</code> event.
		 *
		 * <p>The properties of the event object have the following values:</p>
		 * <table class=innertable>
		 * 		<tr><th>Property</th><th>Value</th></tr>
		 * 		<tr><td>theseusUser</td><td>The TheseusUser that dispatched this event</td></tr>
		 * 		<tr><td>game</td><td>The Game that contains the TheseusUser controller</td></tr>
		 * </table>
		 *
		 * @eventType solverSolutionChange
		 */
		public static const SOLVER_SOLUTION_CHANGE:String = "solverSolutionChange";
		
		private var m_theseusUser:TheseusUser;
		private var m_game:Game;
		
		public function TheseusUserEvent(theseusUser:TheseusUser, game:Game, type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			m_theseusUser = theseusUser;
			m_game = game;
		}
		
		/**
		 * Constructs a new solverBegin event.
		 */
		public static function solverBegin(theseusUser:TheseusUser, game:Game):TheseusUserEvent
		{
			return new TheseusUserEvent(theseusUser, game, SOLVER_BEGIN);
		}
		
		/**
		 * Constructs a new solverEnd event.
		 */
		public static function solverEnd(theseusUser:TheseusUser, game:Game):TheseusUserEvent
		{
			return new TheseusUserEvent(theseusUser, game, SOLVER_END);
		}
		
		/**
		 * Constructs a new solverSolutionChange event.
		 */
		public static function solverSolutionChange(theseusUser:TheseusUser, game:Game):TheseusUserEvent
		{
			return new TheseusUserEvent(theseusUser, game, SOLVER_SOLUTION_CHANGE);
		}
		
		/**
		 * The relevant TheseusUser for the event.
		 */
		public function get theseusUser():TheseusUser
		{
			return m_theseusUser;
		}
		
		/**
		 * The relevant Game for the event.
		 */
		public function get game():Game
		{
			return m_game;
		}
	}
}

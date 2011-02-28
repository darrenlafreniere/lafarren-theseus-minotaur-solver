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
package com.lafarren.tmmaze.core
{
	import flash.utils.Dictionary;

	/**
	 * AS3 doesn't support enums, but this is meant to be treated as such.
	 * Defines the possible move types an agent can potentially make in a maze
	 * instance.
	 */
	public final class MoveType
	{
		public static const UP:MoveType = new MoveType("UP", new PointInt(0, -1));
		public static const DOWN:MoveType = new MoveType("DOWN", new PointInt(0, 1));
		public static const LEFT:MoveType = new MoveType("LEFT", new PointInt(-1, 0));
		public static const RIGHT:MoveType = new MoveType("RIGHT", new PointInt(1, 0));
		public static const SKIP:MoveType = new MoveType("SKIP", new PointInt(0, 0));

		// Internal collection definitions
		private static const m_array:Array =
		[
			UP,
			DOWN,
			LEFT,
			RIGHT,
			SKIP
		];
		private static const m_vector:Vector.<MoveType> = Vector.<MoveType>(m_array);
		
		private static var m_offsetToMoveType:Dictionary;
		
		// Auto-generate an ordinal for each enum instance.
		private static var m_nextOrdinal:int = 0;
		
		// Instance members
		private const m_ordinal:int = m_nextOrdinal++;
		private var m_name:String;
		private var m_offset:PointInt;
		private var m_key:uint;
		
		/**
		 * AS3 doesn't allow for private constructors, but this should be considered as such.
		 */
		public function MoveType(name:String, offset:PointInt)
		{
			m_name = name;
			m_offset = offset;
			m_key = makeKey(offset.x, offset.y);
			
			if (!m_offsetToMoveType)
			{
				m_offsetToMoveType = new Dictionary();
			}
			m_offsetToMoveType[m_key] = this;
		}
		
		/**
		 * The ordinal for this enum constant.
		 */
		public function get ordinal():int
		{
			return m_ordinal;
		}
		
		/**
		 * The name for this enum constant.
		 */
		public function get name():String
		{
			return m_name;
		}
		
		/**
		 * The number of MoveType instances.
		 */
		public static const length:int = m_array.length;
		
		/**
		 * The array of MoveType instances.
		 */
		public static function get array():Array
		{
			return m_array.concat();
		}

		/**
		 * The vector of MoveType instances.
		 */
		public static function get vector():Vector.<MoveType>
		{
			return m_vector.concat();
		}

		
		public static function fromOrdinal(ordinal:int):MoveType
		{
			var v:Vector.<MoveType> = MoveType.vector;
			return (ordinal >= 0 && ordinal < v.length) ? v[ordinal] : null;
		}
		
		/**
		 * Return an offset vector that describes this MoveType.
		 * Note that positive Y is down.
		 * For example, MoveType.UP.toOffset() will return PointInt(0, -1).
		 * @return	The offset vector for the MoveType.
		 */
		public function toOffset():PointInt
		{
			return m_offset.clone();
		}
		
		/**
		 * Return the offset vector's x coordinate that describes this MoveType.
		 * Using offsetX and offsetY can be more efficient than calling
		 * toOffset(), since they do not create a new PointInt object.
		 * 
		 * @return	The offset vector's x coordinate for the MoveType.
		 */
		public function get offsetX():int
		{
			return m_offset.x;
		}
		
		/**
		 * Return the offset vector's y coordinate that describes this MoveType.
		 * Using offsetX and offsetY can be more efficient than calling
		 * toOffset(), since they do not create a new PointInt object.
		 * 
		 * Note that positive Y is down.
		 * 
		 * @return	The offset vector's y coordinate for the MoveType.
		 */
		public function get offsetY():int
		{
			return m_offset.y;
		}
		
		/**
		 * Given an offset vector, this method returns the MoveType that it
		 * describes, or null if a MoveType could not be determined.
		 * @param	offset A normalized vector along the x or y axis,
		 * 			or a zero length vector.
		 * @return	The MoveType the offset vector described, or null.
		 */
		public static function fromOffset(offset:PointInt):MoveType
		{
			return fromOffsetXy(offset.x, offset.y);
		}
		
		/**
		 * Given an offset xy, this method returns the MoveType that it
		 * describes, or null if a MoveType could not be determined.
		 * @param	offsetX The x coordinate of a normalized vector along
		 * 			the x or y axis, or a zero length vector.
		 * @param	offsetY The y coordinate of a normalized vector along
		 * 			the x or y axis, or a zero length vector.
		 * @return	The MoveType the offset vector described, or null.
		 */
		public static function fromOffsetXy(offsetX:int, offsetY:int):MoveType
		{
			return m_offsetToMoveType[makeKey(offsetX, offsetY)];
		}
		
		private static function makeKey(offsetX:int, offsetY:int):uint
		{
			return (offsetX << 16) | (offsetY & 0x0000FFFF);
		}
	}
}

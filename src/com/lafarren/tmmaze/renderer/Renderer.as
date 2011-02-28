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
package com.lafarren.tmmaze.renderer
{
	import com.lafarren.tmmaze.core.Game;
	import com.lafarren.tmmaze.core.GameEvent;
	import com.lafarren.tmmaze.core.Maze;
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import mx.binding.utils.BindingUtils;
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.controls.Image;
	import mx.events.ResizeEvent;
	
	import com.lafarren.tmmaze.core.EntityType;
	import com.lafarren.tmmaze.core.MazeAnimated;
	import com.lafarren.tmmaze.core.MazeDefinition;
	import com.lafarren.tmmaze.core.MoveType;
	import com.lafarren.tmmaze.core.PointInt;
	
	/*
	 * Implements the basic Theseus and Minotaur renderer, similar to that
	 * found here:
	 * http://www.logicmazes.com/theseus.html
	 */
	public class Renderer
	{
		[Embed(source="/../assets/icons/theseus.png")]
		private static const IconTheseus:Class;
		
		[Embed(source="/../assets/icons/theseus-succeed.png")]
		private static const IconTheseusSucceed:Class;
		
		[Embed(source="/../assets/icons/theseus-fail.png")]
		private static const IconTheseusFail:Class;
		
		[Embed(source="/../assets/icons/minotaur.png")]
		private static const IconMinotaur:Class;
		
		private static const TILE_SIZE:int = 40;
		
		private static const TILE_BORDER_THICKNESS:int   = 1;
		private static const WALL_THICKNESS:int          = 3;
		private static const AGENT_OUTLINE_THICKNESS:int = 1;
		
		private static const BACKGROUND_COLOR:uint       = 0xFFFFFF;
		private static const TILE_BASE_COLOR:uint        = 0x000000;
		private static const TILE_BASE_ALPHA:Number      = 0.1;
		private static const TILE_BORDER_COLOR:uint      = 0x00FFFF;
		private static const WALL_COLOR:uint             = 0x000000;
		private static const THESEUS_FILL_COLOR:uint     = 0x0088FF;
		private static const THESEUS_OUTLINE_COLOR:uint  = 0x004488;
		private static const MINOTAUR_FILL_COLOR:uint    = 0xFF0000;
		private static const MINOTAUR_OUTLINE_COLOR:uint = 0x880000;
		
		private var m_target:Canvas;
		private var m_game:Game;
		private var m_solverIconComponent:SolverIconComponent;
		private var m_isTheseusInDanger:Boolean;
		
		private var m_mazeComponent:UIComponent;
		private var m_entityComponents:Vector.<UIComponent>;
		private var m_tileSprite:Sprite;
		
		public function Renderer()
		{
			m_solverIconComponent = new SolverIconComponent();
			m_solverIconComponent.transitionSeconds = 0.2;
			m_solverIconComponent.strobe = true;
		}
		
		/**
		 * The pixel space width of the current game.
		 */
		public function get width():Number
		{
			return this.game && this.game.maze
				? this.game.maze.numCols * TILE_SIZE
				: 0;
		}
		
		/**
		 * The pixel space height of the current game.
		 */
		public function get height():Number
		{
			return this.game && this.game.maze
				? this.game.maze.numRows * TILE_SIZE
				: 0;
		}
		
		/**
		 * The target canvas to render the scene into. The renderer
		 * automatically resizes the canvas to the exact width and
		 * height needed.
		 * 
		 * Setting a null target will disable the renderer.
		 */
		public function get target():Canvas
		{
			return m_target;
		}
		
		public function set target(target:Canvas):void
		{
			if (m_target != target)
			{
				var targetOld:Canvas = m_target;
				m_target = target;
				resizeTarget();
				
				onTargetNew(targetOld, m_target);
			}
		}
		
		/**
		 * The game drawn by the renderer.
		 */
		public function get game():Game
		{
			return m_game;
		}
		
		public function set game(game:Game):void
		{
			if (m_game != game)
			{
				if (m_game)
				{
					m_game.maze.eventDispatcher.removeEventListener(Event.CHANGE, this.onMazeChanged);
				}
				
				var gameOld:Game = m_game;
				m_game = game;
				resizeTarget();
				
				if (m_game)
				{
					m_game.maze.eventDispatcher.addEventListener(Event.CHANGE, this.onMazeChanged);
				}
				
				onGameNew(gameOld, m_game);
			}
		}
		
		/**
		 * The next solution path move to display from the game's Theseus
		 * position, or null if none.
		 */
		public function get solutionPathNextMove():MoveType
		{
			return m_solverIconComponent.moveType;
		}
		
		public function set solutionPathNextMove(moveType:MoveType):void
		{
			m_solverIconComponent.moveType = moveType;
		}
		
		/**
		 * If true, graphically feedback the fact that Theseus is in danger.
		 */
		public function get isTheseusInDanger():Boolean
		{
			return m_isTheseusInDanger;
		}
		
		public function set isTheseusInDanger(isTheseusInDanger:Boolean):void
		{
			if (m_isTheseusInDanger != isTheseusInDanger)
			{
				m_isTheseusInDanger = isTheseusInDanger;
				onIsTheseusInDangerChanged();
			}
		}
		
		// Called when the target changes.
		private function onTargetNew(targetOld:Canvas, targetNew:Canvas):void
		{
			draw();
		}
		
		// Called when the game instance changes.
		private function onGameNew(gameOld:Game, gameNew:Game):void
		{
			if (gameOld)
			{
				gameOld.removeEventListener(GameEvent.END, this.onGameEnded);
			}
			
			if (gameNew)
			{
				gameNew.addEventListener(GameEvent.END, this.onGameEnded);
			}
			
			draw();
		}
		
		// Called when an agent moves.
		private function onMazeChanged(event:Event):void
		{
			updateEntityPosition(EntityType.THESEUS);
			updateEntityPosition(EntityType.MINOTAUR);
		}
		
		// Called when this.isTheseusInDangerChanged changed.
		private function onIsTheseusInDangerChanged():void
		{
			// Swap in or out the danger icon for Theseus
			setEntityIcon(EntityType.THESEUS, getSuggestedEntityIcon(EntityType.THESEUS));
		}
		
		private function onGameEnded(event:GameEvent):void
		{
			// Swap in the special game ending icon for Theseus
			setEntityIcon(EntityType.THESEUS, getSuggestedEntityIcon(EntityType.THESEUS));
		}
		
		private function draw():void
		{
			// Remove any previous sprites
			{
				if (m_mazeComponent)
				{
					m_mazeComponent.parent.removeChild(m_mazeComponent);
					m_mazeComponent = null;
				}
				
				m_entityComponents = null;
			}
			
			if (this.target && this.game)
			{
				drawMaze();
				drawEntities();
				m_mazeComponent.addChild(this.solverIconComponent);
				
				// Set child indices
				var z:int = 0;
				for (var i:int = 0, n:int = EntityType.agentLength; i < n; ++i)
				{
					if (m_entityComponents[i])
					{
						m_mazeComponent.setChildIndex(m_entityComponents[i], z++);
					}
				}
				m_mazeComponent.setChildIndex(m_tileSprite, z++);
				m_mazeComponent.setChildIndex(this.solverIconComponent, z++);
			}
		}
		
		private function drawMaze():void
		{
			// Generate maze sprite. There's some overdraw here, but since
			// this isn't drawn in real time it's all good.
			m_mazeComponent = new UIComponent();
			this.target.addChild(m_mazeComponent);
			var graphics:Graphics = m_mazeComponent.graphics;
			
			// Draw background
			{
				graphics.beginFill(BACKGROUND_COLOR);
				graphics.drawRect(0, 0,  width, height);
				graphics.endFill();
			}
			
			drawWalls(graphics, false, TILE_BORDER_THICKNESS, TILE_BORDER_COLOR);
			drawWalls(graphics, true, WALL_THICKNESS, WALL_COLOR);
			
			drawTiles();
		}
		
		private function drawWalls(graphics:Graphics, wallType:Boolean, thickness:int, color:uint):void
		{
			// WALL_OVERLAP is the amount to extend each wall at its ends
			// to ensure proper overlap.
			const wallOverlap:int = thickness / 2;
			
			// The wall length is the length of the tile, plus the wall thickness
			// to account for the start and end overlap.
			const wallLength:int = TILE_SIZE + thickness;
			
			const maze:Maze = this.game.maze;
			const mazeCols:int = maze.numCols;
			const mazeRows:int = maze.numRows;
			var row:int;
			var col:int;
			
			// Draw horizontal walls
			for (row = 0; row < mazeRows + 1; ++row)
			{
				for (col = 0; col < mazeCols; ++col)
				{
					if (maze.getHorizontalWall(col, row) == wallType)
					{
						if (maze.isTileInside(col, row - 1) || maze.isTileInside(col, row))
						{
							graphics.beginFill(color);
							graphics.drawRect
							(
								(col * TILE_SIZE) - wallOverlap,
								(row * TILE_SIZE) - wallOverlap,
								wallLength,
								thickness
							);
							graphics.endFill();
						}
					}
				}
			}
			
			// Draw vertical walls. There will be some overdraw on the corners 
			for (row = 0; row < mazeRows; ++row)
			{
				for (col = 0; col < mazeCols + 1; ++col)
				{
					if (maze.getVerticalWall(col, row) == wallType)
					{
						if (maze.isTileInside(col - 1, row) || maze.isTileInside(col, row))
						{
							graphics.beginFill(color);
							graphics.drawRect
							(
								(col * TILE_SIZE) - wallOverlap,
								(row * TILE_SIZE) - wallOverlap,
								thickness,
								wallLength
							);
							graphics.endFill();
						}
					}
				}
			}
		}
		
		private function drawTiles():void
		{
			m_tileSprite = new Sprite();
			m_mazeComponent.addChild(m_tileSprite);
			var graphics:Graphics = m_tileSprite.graphics;
			
			const maze:Maze = this.game.maze;
			for (var row:int = 0, numRows:int = maze.numRows; row < numRows; ++row)
			{
				for (var col:int = 0, numCols:int = maze.numCols; col < numCols; ++col)
				{
					if (maze.isTileInside(col, row))
					{
						var x:int = col * TILE_SIZE;
						var y:int = row * TILE_SIZE;
						
						var position:PointInt = new PointInt(col, row);
						if (position.equals(maze.getEntityPosition(EntityType.EXIT)))
						{
							var radians:Number = 0;
							if (maze.isTileInside(col - 1, row))
							{
								radians = 0;
							}
							else if (maze.isTileInside(col, row - 1))
							{
								radians = Math.PI * 0.5;
							}
							else if (maze.isTileInside(col + 1, row))
							{
								radians = Math.PI;
							}
							else if (maze.isTileInside(col, row + 1))
							{
								radians = Math.PI * 1.5;
							}
							
							var colors:Array = [TILE_BASE_COLOR, TILE_BASE_COLOR];
							var alphas:Array = [TILE_BASE_ALPHA, 0.0];
							var ratios:Array = [0x00, 0xFF];
							var matrix:Matrix = new Matrix();
							matrix.createGradientBox(TILE_SIZE, TILE_SIZE, radians, x, y);
							graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, matrix);
						}
						else
						{
							graphics.beginFill(TILE_BASE_COLOR, TILE_BASE_ALPHA);
						}
						
						graphics.drawRect(x, y, TILE_SIZE, TILE_SIZE);
						graphics.endFill();
					}
				}
			}
		}
		
		private function drawEntities():void
		{
			const entityCount:int = EntityType.length;
			m_entityComponents = new Vector.<UIComponent>(entityCount, true);
			for (var i:int = 0; i < entityCount; ++i)
			{
				var entityType:EntityType = EntityType.fromOrdinal(i);
				
				// Only draw agents
				if (entityType.isAgent)
				{
					m_entityComponents[i] = new UIComponent();
					m_mazeComponent.addChild(m_entityComponents[i]);
					
					setEntityIcon(entityType, getSuggestedEntityIcon(entityType));
					
					updateEntityPosition(EntityType.fromOrdinal(i));
				}
			}
			
			var theseusComponent:UIComponent = m_entityComponents[EntityType.THESEUS.ordinal];
			BindingUtils.bindProperty(this.solverIconComponent, "x", theseusComponent, "x");
			BindingUtils.bindProperty(this.solverIconComponent, "y", theseusComponent, "y");
		}
		
		private function setEntityIcon(entityType:EntityType, iconClass:Class):void
		{
			if (m_entityComponents)
			{
				// Remove existing component images before adding the new one.
				// Iterate backwards so removal doesn't affect iteration.
				var entityComponent:UIComponent = m_entityComponents[entityType.ordinal];
				if (entityComponent)
				{
					for (var i:int = entityComponent.numChildren; --i >= 0; )
					{
						if (entityComponent.getChildAt(i) as Image)
						{
							entityComponent.removeChildAt(i);
						}
					}
					
					var bitmap:Bitmap = new iconClass();
					var image:Image = new Image();
					image.source = bitmap;
					image.width = bitmap.width;
					image.height = bitmap.height;
					image.x = -(image.width / 2);
					image.y = -(image.height / 2);
					
					entityComponent.addChild(image);
				}
			}
		}
		
		// Returns the currently suggested icon class for the entity type.
		private function getSuggestedEntityIcon(entityType:EntityType):Class
		{
			var result:Class;
			if (entityType == EntityType.THESEUS)
			{
				result = IconTheseus;
				if (m_game)
				{
					if (m_isTheseusInDanger || m_game.hasSucceeded(EntityType.MINOTAUR))
					{
						result = IconTheseusFail;
					}
					else if (m_game.hasSucceeded(EntityType.THESEUS))
					{
						result = IconTheseusSucceed;
					}
				}
			}
			else
			{
				result = IconMinotaur;
			}
			
			return result;
		}
		
		private function updateEntityPosition(entityType:EntityType):void
		{
			var entityComponent:UIComponent = m_entityComponents[entityType.ordinal];
			if (entityComponent)
			{
				var position:Point = this.game.maze.getEntityPositionFloat(entityType);
				entityComponent.x = (TILE_SIZE * position.x) + (TILE_SIZE / 2.0);
				entityComponent.y = (TILE_SIZE * position.y) + (TILE_SIZE / 2.0);
			}
		}
		
		private function get solverIconComponent():SolverIconComponent
		{
			return m_solverIconComponent;
		}
		
		private function resizeTarget():void
		{
			if (m_target)
			{
				m_target.width = this.width;
				m_target.height = this.height;
			}
		}
	}
}
